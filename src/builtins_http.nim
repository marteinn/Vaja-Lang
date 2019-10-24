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
type HttpServer* = ref object of NativeValue
  instance: AsyncHttpServer
  routes*: seq[(Obj, Obj)]

proc httpCreateServer(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  var server = newAsyncHttpServer()
  return newNativeObject(
    nativeValue=HttpServer(instance: server, routes: @[])
  )

proc httpAddRoutes(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) != 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )
  let
    arr: Obj = arguments[0]
  var
    server: Obj = arguments[1]
  if arr.objType != ObjType.OTArray:
    return newError(errorMsg="Argument arr was " & $(arr.objType) & ", want Array")
  if server.objType != ObjType.OTNativeObject:
    return newError(errorMsg="Argument arr was " & $(server.objType) & ", want NativeObject")
  let httpServer: HttpServer = cast[HttpServer](server.nativeValue)
  let routes: seq[(Obj, Obj)] = map(arr.arrayElements, proc(routeObj: Obj): (Obj, Obj) =
    (routeObj.arrayElements[0], routeObj.arrayElements[1])
  )

  httpServer.routes = routes
  return server

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

proc getMatchingPattern(req: Request, routes: seq[(Obj, Obj)]): seq[Obj] =
  for route in routes:
    let
      pattern = route[0]
      handler = route[1]

    if req.url.path == pattern.strValue:
      return @[handler]
  return @[]

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
  let
    reqHashMapElements: OrderedTable[string, Obj] = {
      "hostname": newStr(strValue=req.hostname),
      "scheme": newStr(strValue=req.url.scheme),
      "path": newStr(strValue=req.url.path),
      "port": newStr(strValue=req.url.port),
      "anchor": newStr(strValue=req.url.anchor),
      "query": newStr(strValue=req.url.query),
      # method
    }.toOrderedTable
    reqHashMap = newHashMap(hashMapElements=reqHashMapElements)
  return @[reqHashMap]

proc httpCall(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  let
    url = arguments[0].strValue
    # 1 data/body
    # 2 config
    server = arguments[3]
    httpServer: HttpServer = cast[HttpServer](server.nativeValue)
    routes: seq[(Obj, Obj)]= httpServer.routes
  var
    uri = initUri()
  parseUri(url, uri)
  let
    req = Request(hostname: uri.hostname, url: uri)
    handlerArgs: seq[Obj] = reqToHandlerArgs(req)
    matchingHandlers: seq[Obj] = getMatchingPattern(req, routes)

  var fnEnv: Env = newEnv()
  return applyFn(matchingHandlers[0], handlerArgs, fnEnv)

proc httpListen(arguments: seq[Obj], applyFn: ApplyFunction): Obj =
  if len(arguments) != 2:
    return newError(
      errorMsg="Wrong number of arguments, got " & $len(arguments) & ", want 2"
    )

  let
    port: Obj = arguments[0]
    server: Obj = arguments[1]
  if port.objType != ObjType.OTInteger:
    return newError(errorMsg="Argument arr was " & $(port.objType) & ", want Integer")
  if server.objType != ObjType.OTNativeObject:
    return newError(errorMsg="Argument arr was " & $(server.objType) & ", want NativeObject")

  assert(server.nativeValue of HttpServer)
  let
    httpServer: HttpServer = cast[HttpServer](server.nativeValue)
    nativeServer = httpServer.instance
    routes: seq[(Obj, Obj)]= httpServer.routes

  proc cb(req: Request) {.async.} =
    let
      handlerArgs: seq[Obj] = reqToHandlerArgs(req)
      matchingHandlers: seq[Obj] = getMatchingPattern(req, routes)

    if len(matchingHandlers) == 0:
      await req.respond(Http500, "Internal error, no matching route")
    else:
      {.gcsafe}:
        var fnEnv: Env = newEnv()
        let response: Obj = applyFn(matchingHandlers[0], handlerArgs, fnEnv)

      await responseHandlerResponse(req, response)

  waitFor nativeServer.serve(Port(port.intValue), cb)
  return NIL

let functions*: OrderedTable[string, Obj] = {
  "createServer": newBuiltin(builtinFn=httpCreateServer),
  "addRoutes": newBuiltin(builtinFn=httpAddRoutes),
  "listen": newBuiltin(builtinFn=httpListen),
  "call": newBuiltin(builtinFn=httpCall),
}.toOrderedTable

let httpModule*: Obj = newHashMap(hashMapElements=functions)
