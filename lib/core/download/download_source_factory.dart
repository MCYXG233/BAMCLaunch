import 'download_source.dart';
import 'i_download_source.dart';

class DownloadSourceFactory {
  static List<IDownloadSource> createDefaultSources() {
    return [
      _createOfficialSource(),
      _createBMCLAPISource(),
      _createMCBBSSource(),
    ];
  }

  static DownloadSource _createOfficialSource() {
    return DownloadSource(
      name: '官方源',
      baseUrl: 'https://launcher.mojang.com',
      mirrors: [
        'https://launcher.mojang.com',
      ],
    );
  }

  static DownloadSource _createBMCLAPISource() {
    return DownloadSource(
      name: 'BMCLAPI',
      baseUrl: 'https://bmclapi2.bangbang93.com',
      mirrors: [
        'https://bmclapi2.bangbang93.com',
        'https://bmclapi.bangbang93.com',
      ],
    );
  }

  static DownloadSource _createMCBBSSource() {
    return DownloadSource(
      name: 'MCBBS',
      baseUrl: 'https://download.mcbbs.net',
      mirrors: [
        'https://download.mcbbs.net',
      ],
    );
  }

  static DownloadSource createCustomSource({
    required String name,
    required String baseUrl,
    required List<String> mirrors,
  }) {
    return DownloadSource(
      name: name,
      baseUrl: baseUrl,
      mirrors: mirrors,
    );
  }
}