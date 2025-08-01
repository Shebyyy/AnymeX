import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:anymex/core/Model/settings.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
as flutter_inappwebview;
import 'package:http/io_client.dart';
import 'package:http_interceptor/http_interceptor.dart';
import '../../../main.dart';
import '../Eval/dart/model/m_source.dart';

class MClient {
  MClient();
  static InterceptedClient init(
      {MSource? source,
      Map<String, dynamic>? reqcopyWith,
      }) {
    return InterceptedClient.build(
        client: IOClient(HttpClient()),
        interceptors: [MCookieManager(reqcopyWith), LoggerInterceptor()]);
  }

  static Map<String, String> getCookiesPref(String url) {
    final cookiesList = isar.settings.getSync(227)!.cookiesList ?? [];
    if (cookiesList.isEmpty) return {};
    final cookies = cookiesList
        .firstWhere(
          (element) =>
              element.host == Uri.parse(url).host ||
              Uri.parse(url).host.contains(element.host!),
          orElse: () => MCookie(cookie: ""),
        )
        .cookie!;
    if (cookies.isEmpty) return {};
    return {HttpHeaders.cookieHeader: cookies};
  }

  static Future<void> setCookie(String url, String ua,
      flutter_inappwebview.InAppWebViewController? webViewController,
      {String? cookie}) async {
    List<String> cookies = [];
    if (Platform.isLinux) {
      cookies = cookie
              ?.split(RegExp('(?<=)(,)(?=[^;]+?=)'))
              .where((cookie) => cookie.isNotEmpty)
              .toList() ??
          [];
    } else {
      cookies = (await flutter_inappwebview.CookieManager.instance(
                  webViewEnvironment: webViewEnvironment)
              .getCookies(
                  url: flutter_inappwebview.WebUri(url),
                  webViewController: webViewController))
          .map((e) => "${e.name}=${e.value}")
          .toList();
    }
    if (cookies.isNotEmpty) {
      final host = Uri.parse(url).host;
      final newCookie = cookies.join("; ");
      final settings = isar.settings.getSync(227);
      List<MCookie>? cookieList = [];
      for (var cookie in settings!.cookiesList ?? []) {
        if (cookie.host != host || (!host.contains(cookie.host))) {
          cookieList.add(cookie);
        }
      }
      cookieList.add(MCookie()
        ..host = host
        ..cookie = newCookie);
      isar.writeTxnSync(
          () => isar.settings.putSync(settings..cookiesList = cookieList));
    }
    if (ua.isNotEmpty) {
      final settings = isar.settings.getSync(227);
      isar.writeTxnSync(() => isar.settings.putSync(settings!..userAgent = ua));
    }
  }

  static void deleteAllCookies(String url) {
    final cookiesList = isar.settings.getSync(227)!.cookiesList ?? [];
    List<MCookie>? cookieList = [];
    for (var cookie in cookiesList) {
      if (!(cookie.host == Uri.parse(url).host ||
          Uri.parse(url).host.contains(cookie.host!))) {
        cookieList.add(cookie);
      }
    }
    isar.writeTxnSync(() => isar.settings
        .putSync(isar.settings.getSync(227)!..cookiesList = cookieList));
  }
}

class MCookieManager extends InterceptorContract {
  MCookieManager(this.reqcopyWith);

  Map<String, dynamic>? reqcopyWith;

  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    final cookie = MClient.getCookiesPref(request.url.toString());
    if (cookie.isNotEmpty) {
      final userAgent = isar.settings.getSync(227)!.userAgent!;
      if (request.headers[HttpHeaders.cookieHeader] == null) {
        request.headers.addAll(cookie);
      }
      if (request.headers[HttpHeaders.userAgentHeader] == null) {
        request.headers[HttpHeaders.userAgentHeader] = userAgent;
      }
    }
    try {
      if (reqcopyWith != null) {
        if (reqcopyWith!["followRedirects"] != null) {
          request.followRedirects = reqcopyWith!["followRedirects"];
        }
        if (reqcopyWith!["maxRedirects"] != null) {
          request.maxRedirects = reqcopyWith!["maxRedirects"];
        }
        if (reqcopyWith!["contentLength"] != null) {
          request.contentLength = reqcopyWith!["contentLength"];
        }
        if (reqcopyWith!["persistentConnection"] != null) {
          request.persistentConnection = reqcopyWith!["persistentConnection"];
        }
      }
    } catch (_) {}
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    return response;
  }
}

class LoggerInterceptor extends InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    log(
        '----- Request -----\n${request.toString()}\nheader: ${request.headers.toString()}');
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    final cloudflare = [403, 503].contains(response.statusCode) &&
        ["cloudflare-nginx", "cloudflare"].contains(response.headers["server"]);
    log(
        "----- Response -----\n${response.request?.method}: ${response.request?.url}, statusCode: ${response.statusCode} ${cloudflare ? "Failed to bypass Cloudflare" : ""}");
    debugPrint(
        "----- Response -----\n${response.request?.method}: ${response.request?.url}, statusCode: ${response.statusCode} ${cloudflare ? "Failed to bypass Cloudflare" : ""}");
    if (cloudflare) {
      errorSnackBar("${response.statusCode} Failed to bypass Cloudflare");
    }
    return response;
  }
}
