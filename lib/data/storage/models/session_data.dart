import 'dart:convert';

class SessionData {
    final String url;
    final String cookies;
    final String? csrfToken;

    SessionData({
        required this.url,
        required this.cookies,
        required this.csrfToken,
    });

    SessionData copyWith({
        String? url,
        String? cookies,
        String? csrfToken,
    }) => 
        SessionData(
            url: url ?? this.url,
            cookies: cookies ?? this.cookies,
            csrfToken: csrfToken ?? this.csrfToken,
        );

    factory SessionData.fromRawJson(String str) => SessionData.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
        url: json["url"],
        cookies: json["cookies"],
        csrfToken: json["csrfToken"],
    );

    Map<String, dynamic> toJson() => {
        "url": url,
        "cookies": cookies,
        "csrfToken": csrfToken,
    };
}

class StoredSessionData {
    final List<SessionData> sessionData;

    StoredSessionData({
        required this.sessionData,
    });

    StoredSessionData copyWith({
        List<SessionData>? sessionData,
    }) => 
        StoredSessionData(
            sessionData: sessionData ?? this.sessionData,
        );

    factory StoredSessionData.fromRawJson(String str) => StoredSessionData.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory StoredSessionData.fromJson(Map<String, dynamic> json) => StoredSessionData(
        sessionData: List<SessionData>.from(json["sessionData"].map((x) => SessionData.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "sessionData": List<dynamic>.from(sessionData.map((x) => x.toJson())),
    };
}
