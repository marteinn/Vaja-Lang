import tables
import uri
import sequtils
import asynchttpserver, asyncdispatch
from obj import
  Obj,
  ObjType,
  NativeValue,
  ApplyFunction,
  newBuiltin,
  newHashMap,
  newStr,
  newError,
  newInteger,
  newArray,
  newNativeObject,
  Env,
  newEnv,
  NIL,
  inspect
import test_utils

type HttpServer* = ref object of NativeValue
  instance: AsyncHttpServer
  handler*: Obj

proc httpCreateServer(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 0)

  var server = newAsyncHttpServer()
  return newNativeObject(
    nativeValue=HttpServer(instance: server, handler: nil)
  )

proc httpAddHandler(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 2)
  requireArgOfTypes(arguments, 0, @[ObjType.OTFunction, ObjType.OTFunctionGroup])
  requireArgOfType(arguments, 1, ObjType.OTNativeObject)

  let
    handler: Obj = arguments[0]
  var
    server: Obj = arguments[1]
  let
    httpServer: HttpServer = cast[HttpServer](server.nativeValue)
  httpServer.handler = handler
  return server

proc httpMethodToStr(httpMethod: HttpMethod): string =
  case httpMethod:
    of HttpHead: "head"
    of HttpGet: "get"
    of HttpPost: "post"
    of HttpPut: "put"
    of HttpDelete: "delete"
    of HttpTrace: "trace"
    of HttpOptions: "options"
    of HttpConnect:" connect"
    of HttpPatch: "patch"

proc httpMethodToEnum(httpMethod: string): HttpMethod =
  case httpMethod:
    of "head": HttpHead
    of "get": HttpGet
    of "post": HttpPost
    of "put": HttpPut
    of "delete": HttpDelete
    of "trace": HttpTrace
    of "options": HttpOptions
    of "connect": HttpConnect
    of "patch": HttpPatch
    else: HttpHead

proc intCodeToHttpCode(code: int): HttpCode =
  case code:
    of 100: Http100
    of 101: Http101
    of 200: Http200
    of 201: Http201
    of 202: Http202
    of 203: Http203
    of 204: Http204
    of 205: Http205
    of 206: Http206
    of 300: Http300
    of 301: Http301
    of 302: Http302
    of 303: Http303
    of 304: Http304
    of 305: Http305
    of 307: Http307
    of 400: Http400
    of 401: Http401
    of 403: Http403
    of 404: Http404
    of 405: Http405
    of 406: Http406
    of 407: Http407
    of 408: Http408
    of 409: Http409
    of 410: Http410
    of 411: Http411
    of 412: Http412
    of 413: Http413
    of 414: Http414
    of 415: Http415
    of 416: Http416
    of 417: Http417
    of 418: Http418
    of 421: Http421
    of 422: Http422
    of 426: Http426
    of 428: Http428
    of 429: Http429
    of 431: Http431
    of 451: Http451
    of 500: Http500
    of 501: Http501
    of 502: Http502
    of 503: Http503
    of 504: Http504
    of 505: Http505
    else: Http418  # I'm a teapot

proc headersToResponseHeaders(headers: Obj): seq[(string, string)] =
  headers.arrayElements
    .filter(proc (x: Obj): bool = x.objType == ObjType.OTArray)
    .map(proc (x: Obj): seq[string] =
      x.arrayElements
        .filter(proc(y: Obj): bool = y.objType == ObjType.OTString)
        .map(proc(y: Obj): string = y.strValue)
    )
    .filter(proc (x: seq[string]): bool = len(x) == 2)
    .map(proc (x: seq[string]): (string, string) = (x[0], x[1]))

proc responseHandlerResponse(req: Request, response: Obj): Future[void] =
  if response.objType != ObjType.OTHashMap:
    return req.respond(Http500, "Internal error, handler must return HashMap")

  let
    unpackedResponse = response.hashMapElements
  if "body" in unpackedResponse and
    unpackedResponse["body"].objType != ObjType.OTString:
    return req.respond(Http500, "Internal error, response body must be string")

  if "status" in unpackedResponse and
    unpackedResponse["status"].objType != ObjType.OTInteger:
    return req.respond(Http500, "Internal error, response body must be integer")

  if "headers" in unpackedResponse and
    unpackedResponse["headers"].objType != ObjType.OTArray:
    return req.respond(Http500, "Internal error, response headers must be array")

  let
    body: string =
      if "body" in unpackedResponse:
        unpackedResponse["body"].strValue
      else:
        ""
    code: int =
      if "status" in unpackedResponse:
        unpackedResponse["status"].intValue
      else:
        200
    headers: seq[(string, string)] =
      if "headers" in unpackedResponse:
        headersToResponseHeaders(unpackedResponse["headers"])
      else:
        @[]

  req.respond(intCodeToHttpCode(code), body, newHttpHeaders(headers))

proc reqToHandlerArgs(req: Request): seq[Obj] =
  var headerObjs: seq[Obj] = @[]
  for key, val in req.headers:
    let obj: Obj = newArray(
      arrayElements= @[newStr(strValue=key), newStr(strValue=val)]
    )
    headerObjs.add(obj)

  let
    protocol: OrderedTable[string, Obj] = {
      "protocol": newStr(strValue=req.protocol.orig),
      "major": newStr(strValue= $(req.protocol.major)),
      "minor": newStr(strValue= $(req.protocol.minor)),
    }.toOrderedTable
    reqHashMapElements: OrderedTable[string, Obj] = {
      "hostname": newStr(strValue=req.hostname),
      "scheme": newStr(strValue=req.url.scheme),
      "path": newStr(strValue=req.url.path),
      "port": newStr(strValue=req.url.port),
      "anchor": newStr(strValue=req.url.anchor),
      "query": newStr(strValue=req.url.query),
      "method": newStr(strValue=httpMethodToStr(req.reqMethod)),
      "body": newStr(strValue=req.body),
      "headers": newArray(arrayElements=headerObjs),
      "protocol": newHashMap(hashMapElements=protocol),
    }.toOrderedTable
    reqHashMap = newHashMap(hashMapElements=reqHashMapElements)
  return @[reqHashMap]

proc httpCall(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  let
    url = arguments[0].strValue
    callMethod = arguments[1].strValue
    body = arguments[2].strValue
    callHeaders: seq[(string, string)] = arguments[3].arrayElements.map(
      proc (x: Obj): (string, string) =
        (x.arrayElements[0].strValue, x.arrayElements[1].strValue)
      )
    server = arguments[4]
    httpServer: HttpServer = cast[HttpServer](server.nativeValue)
  var
    uri = initUri()
  parseUri(url, uri)
  let
    headers = newHttpHeaders(callHeaders)
    req = Request(
      hostname: uri.hostname,
      url: uri,
      reqMethod: httpMethodToEnum(callMethod),
      body: body,
      headers: headers,
      protocol: ("HTTP/1.1", 1, 1),
    )
    handlerArgs: seq[Obj] = reqToHandlerArgs(req)
  var fnEnv: Env = newEnv()
  let
    repObj = applyFn(httpServer.handler, handlerArgs, fnEnv)
    callResp: OrderedTable[string, Obj] = {
      "response": repObj,
      "request": handlerArgs[0],
    }.toOrderedTable
  return newHashMap(hashMapElements=callResp)

proc httpListen(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  requireNumArgs(arguments, 2)
  requireArgOfType(arguments, 0, ObjType.OTInteger)
  requireArgOfType(arguments, 1, ObjType.OTNativeObject)

  let
    port: Obj = arguments[0]
    server: Obj = arguments[1]
  assert(server.nativeValue of HttpServer)
  let
    httpServer: HttpServer = cast[HttpServer](server.nativeValue)
    nativeServer = httpServer.instance
    handler: Obj = httpServer.handler
  proc cb(req: Request) {.async.} =
    let
      handlerArgs: seq[Obj] = reqToHandlerArgs(req)
    {.gcsafe}:
      var fnEnv: Env = newEnv()
      let response: Obj = applyFn(handler, handlerArgs, fnEnv)
    await responseHandlerResponse(req, response)

  waitFor nativeServer.serve(Port(port.intValue), cb)
  return NIL

let functions*: OrderedTable[string, Obj] = {
  "createServer": newBuiltin(builtinFn=httpCreateServer),
  "addHandler": newBuiltin(builtinFn=httpAddHandler),
  "listen": newBuiltin(builtinFn=httpListen),
  "call": newBuiltin(builtinFn=httpCall),
}.toOrderedTable

let httpModule*: Obj = newHashMap(hashMapElements=functions)
