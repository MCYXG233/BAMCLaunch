import 'package:flutter/material.dart';
import '../../../../core/version/interfaces/i_version_manager.dart';
import '../../../../core/version/models/loader_models.dart';
import '../../components/buttons/bamc_button.dart';
import '../../components/inputs/bamc_input.dart';
import '../../components/progress/bamc_progress_bar.dart';

class LoaderInstallTestPage extends StatefulWidget {
  final IVersionManager versionManager;

  const LoaderInstallTestPage({
    super.key,
    required this.versionManager,
  });

  @override
  State<LoaderInstallTestPage> createState() => _LoaderInstallTestPageState();
}

class _LoaderInstallTestPageState extends State<LoaderInstallTestPage> {
  final _mcVersionController = TextEditingController(text: '1.20.1');
  final _loaderVersionController = TextEditingController(text: '47.2.1');
  LoaderType _selectedLoader = LoaderType.forge;
  double _progress = 0.0;
  String _status = 'Ready';
  LoaderInstallStatus _installStatus = LoaderInstallStatus.pending;
  List<String> _compatibleVersions = [];

  void _checkCompatibility() async {
    setState(() {
      _status = 'Checking compatibility...';
    });

    try {
      final info = await widget.versionManager.checkLoaderCompatibility(
        _selectedLoader,
        _mcVersionController.text,
        _loaderVersionController.text,
      );

      setState(() {
        _compatibleVersions = info.compatibleLoaderVersions;
        if (info.isCompatible) {
          _status = 'Compatible!';
        } else {
          _status = 'Not compatible: ${info.reason}';
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  void _installLoader() async {
    setState(() {
      _progress = 0.0;
      _status = 'Starting installation...';
    });

    try {
      final result = await widget.versionManager.installLoader(
        loaderType: _selectedLoader,
        mcVersion: _mcVersionController.text,
        loaderVersion: _loaderVersionController.text,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
        onStatusChanged: (status) {
          setState(() {
            _installStatus = status;
            _status = status.toString().split('.').last;
          });
        },
      );

      if (result.success) {
        setState(() {
          _status = 'Installation successful! Version ID: ${result.versionId}';
        });
      } else {
        setState(() {
          _status = 'Installation failed: ${result.errorMessage}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  void _getLoaderVersions() async {
    setState(() {
      _status = 'Fetching loader versions...';
    });

    try {
      final versions = await widget.versionManager.getLoaderVersions(
        _selectedLoader,
        _mcVersionController.text,
      );

      setState(() {
        _compatibleVersions = versions.map((v) => v.version).toList();
        _status = 'Found ${versions.length} versions';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loader Install Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Loader Type: '),
                DropdownButton<LoaderType>(
                  value: _selectedLoader,
                  onChanged: (value) {
                    setState(() {
                      _selectedLoader = value!;
                    });
                  },
                  items: LoaderType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BamcInput(
              controller: _mcVersionController,
              labelText: 'Minecraft Version',
              hintText: 'e.g. 1.20.1',
            ),
            const SizedBox(height: 16),
            BamcInput(
              controller: _loaderVersionController,
              labelText: 'Loader Version',
              hintText: 'e.g. 47.2.1',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                BamcButton(
                  onPressed: _getLoaderVersions,
                  text: 'Get Loader Versions',
                ),
                const SizedBox(width: 16),
                BamcButton(
                  onPressed: _checkCompatibility,
                  text: 'Check Compatibility',
                ),
                const SizedBox(width: 16),
                BamcButton(
                  onPressed: _installLoader,
                  text: 'Install Loader',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Status: $_status'),
            const SizedBox(height: 16),
            BamcProgressBar(
              value: _progress,
              label: 'Installation Progress',
            ),
            const SizedBox(height: 24),
            const Text('Compatible Versions:'),
            Expanded(
              child: ListView.builder(
                itemCount: _compatibleVersions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_compatibleVersions[index]),
                    onTap: () {
                      _loaderVersionController.text = _compatibleVersions[index];
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}