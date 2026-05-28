import 'dart:convert';
import 'dart:io';
import '../core/logger.dart';

class AuthlibInjector {
  static AuthlibInjector? _instance;

  factory AuthlibInjector() {
    return _instance ??= AuthlibInjector._internal();
  }

  AuthlibInjector._internal();

  static AuthlibInjector get instance => _instance ??= AuthlibInjector._internal();

  final Logger _logger = Logger('AuthlibInjector');

  Future<bool> checkAuthlibJarExists() async {
    final jarPath = await getAuthlibJarPath();
    return File(jarPath).exists();
  }

  Future<String> getAuthlibJarPath() async {
    return '${Directory.current.path}/lib/authlib-injector.jar';
  }

  Future<void> downloadAuthlibJar() async {
    _logger.info('Downloading authlib-injector.jar');
    final jarPath = await getAuthlibJarPath();
    final file = File(jarPath);
    
    if (await file.exists()) {
      _logger.debug('Authlib injector already exists');
      return;
    }

    try {
      final request = await HttpClient().getUrl(Uri.parse('https://github.com/yushijinhun/authlib-injector/releases/latest/download/authlib-injector.jar'));
      final response = await request.close();
      
      await response.pipe(file.openWrite());
      _logger.info('Authlib injector downloaded successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to download authlib injector', e, stackTrace);
      rethrow;
    }
  }

  Future<AuthServerInfo> getAuthServerInfo(String authServerUrl) async {
    _logger.debug('Getting auth server info from: $authServerUrl');
    
    try {
      final wellKnownUrl = Uri.parse(authServerUrl).resolve('.well-known/minecraft/services');
      final request = await HttpClient().getUrl(wellKnownUrl);
      final response = await request.close();
      
      if (response.statusCode != 200) {
        return await _fetchLegacyMetadata(authServerUrl);
      }
      
      final content = await response.transform(utf8.decoder).join();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      return AuthServerInfo(
        authUrl: authServerUrl,
        clientId: json['client_id'] as String?,
        metadata: AuthServerMetadata.fromJson(json),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e, stackTrace) {
      _logger.warn('Failed to get auth server info, falling back to legacy: $e');
      return await _fetchLegacyMetadata(authServerUrl);
    }
  }

  Future<AuthServerInfo> _fetchLegacyMetadata(String authServerUrl) async {
    try {
      final request = await HttpClient().getUrl(Uri.parse('$authServerUrl/api/profiles/minecraft'));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      
      final response = await request.close();
      if (response.statusCode == 200 || response.statusCode == 400) {
        return AuthServerInfo(
          authUrl: authServerUrl,
          clientId: null,
          metadata: AuthServerMetadata(
            name: 'Custom Auth Server',
            description: 'Third-party authentication server',
            icon: null,
            links: null,
          ),
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      _logger.debug('Legacy metadata fetch failed: $e');
    }
    
    return AuthServerInfo(
      authUrl: authServerUrl,
      clientId: null,
      metadata: AuthServerMetadata(
        name: 'Unknown Server',
        description: 'Unknown authentication server',
        icon: null,
        links: null,
      ),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<UserProfile> authenticate(String authServerUrl, String username, String password) async {
    _logger.info('Authenticating with server: $authServerUrl');
    
    try {
      final request = await HttpClient().postUrl(Uri.parse('$authServerUrl/authserver/authenticate'));
      request.headers.set('Content-Type', 'application/json');
      
      final body = jsonEncode({
        'agent': {
          'name': 'Minecraft',
          'version': 1,
        },
        'username': username,
        'password': password,
      });
      
      request.write(body);
      final response = await request.close();
      
      if (response.statusCode != 200) {
        final errorContent = await response.transform(utf8.decoder).join();
        throw Exception('Authentication failed: $errorContent');
      }
      
      final content = await response.transform(utf8.decoder).join();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      return UserProfile.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Authentication failed', e, stackTrace);
      rethrow;
    }
  }

  Future<UserProfile> refresh(String authServerUrl, String accessToken, String clientToken) async {
    _logger.debug('Refreshing token with server: $authServerUrl');
    
    try {
      final request = await HttpClient().postUrl(Uri.parse('$authServerUrl/authserver/refresh'));
      request.headers.set('Content-Type', 'application/json');
      
      final body = jsonEncode({
        'accessToken': accessToken,
        'clientToken': clientToken,
      });
      
      request.write(body);
      final response = await request.close();
      
      if (response.statusCode != 200) {
        throw Exception('Refresh failed');
      }
      
      final content = await response.transform(utf8.decoder).join();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      return UserProfile.fromJson(json);
    } catch (e, stackTrace) {
      _logger.error('Token refresh failed', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> validate(String authServerUrl, String accessToken) async {
    _logger.debug('Validating token with server: $authServerUrl');
    
    try {
      final request = await HttpClient().postUrl(Uri.parse('$authServerUrl/authserver/validate'));
      request.headers.set('Content-Type', 'application/json');
      
      final body = jsonEncode({
        'accessToken': accessToken,
      });
      
      request.write(body);
      final response = await request.close();
      
      return response.statusCode == 200;
    } catch (e) {
      _logger.debug('Validation failed: $e');
      return false;
    }
  }
}

class AuthServerInfo {
  final String authUrl;
  final String? clientId;
  final AuthServerMetadata metadata;
  final int timestamp;

  AuthServerInfo({
    required this.authUrl,
    this.clientId,
    required this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'authUrl': authUrl,
      'clientId': clientId,
      'metadata': metadata.toJson(),
      'timestamp': timestamp,
    };
  }

  factory AuthServerInfo.fromJson(Map<String, dynamic> json) {
    return AuthServerInfo(
      authUrl: json['authUrl'] as String,
      clientId: json['clientId'] as String?,
      metadata: AuthServerMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      timestamp: json['timestamp'] as int,
    );
  }
}

class AuthServerMetadata {
  final String name;
  final String description;
  final String? icon;
  final Map<String, String>? links;

  AuthServerMetadata({
    required this.name,
    required this.description,
    this.icon,
    this.links,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'links': links,
    };
  }

  factory AuthServerMetadata.fromJson(Map<String, dynamic> json) {
    return AuthServerMetadata(
      name: json['name'] as String? ?? 'Unknown Server',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String?,
      links: json['links'] != null 
          ? Map<String, String>.from(json['links'] as Map)
          : null,
    );
  }
}

class UserProfile {
  final String accessToken;
  final String clientToken;
  final Profile selectedProfile;
  final List<Profile> availableProfiles;

  UserProfile({
    required this.accessToken,
    required this.clientToken,
    required this.selectedProfile,
    required this.availableProfiles,
  });

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'clientToken': clientToken,
      'selectedProfile': selectedProfile.toJson(),
      'availableProfiles': availableProfiles.map((p) => p.toJson()).toList(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      accessToken: json['accessToken'] as String,
      clientToken: json['clientToken'] as String,
      selectedProfile: Profile.fromJson(json['selectedProfile'] as Map<String, dynamic>),
      availableProfiles: (json['availableProfiles'] as List<dynamic>)
          .map((p) => Profile.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Profile {
  final String id;
  final String name;
  final String? skinUrl;
  final String? capeUrl;

  Profile({
    required this.id,
    required this.name,
    this.skinUrl,
    this.capeUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'skinUrl': skinUrl,
      'capeUrl': capeUrl,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      skinUrl: json['skinUrl'] as String?,
      capeUrl: json['capeUrl'] as String?,
    );
  }
}