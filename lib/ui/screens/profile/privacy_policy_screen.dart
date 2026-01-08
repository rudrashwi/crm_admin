import 'package:flutter/material.dart';
import 'package:crm_admin/core/constants/app_colors.dart';
import 'package:crm_admin/core/api/api_client.dart';
import 'package:crm_admin/core/api/api_endpoints.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _isLoading = true;
  String? _error;
  String _markdownContent = '';

  @override
  void initState() {
    super.initState();
    _fetchPrivacyPolicy();
  }

  Future<void> _fetchPrivacyPolicy() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get(
        ApiEndpoints.publicContent,
        queryParameters: {'type': 'PRIVACY_POLICY', 'role': 'ALL'},
      );

      print('[PRIVACY_POLICY] Response: ${response.data}');

      if (response.data != null &&
          response.data['data'] != null &&
          response.data['data']['content'] != null) {
        final content = response.data['data']['content'] as String;
        print('[PRIVACY_POLICY] Content length: ${content.length}');
        print(
          '[PRIVACY_POLICY] First 200 chars: ${content.substring(0, content.length > 200 ? 200 : content.length)}',
        );

        setState(() {
          _markdownContent = content;
          _isLoading = false;
        });
      } else {
        print('[PRIVACY_POLICY] No content in response');
        setState(() {
          _error = 'No privacy policy content available';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[PRIVACY_POLICY] Error: $e');
      setState(() {
        _error = 'Failed to load privacy policy: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), elevation: 0),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchPrivacyPolicy,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPrivacyPolicy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: _buildMarkdownContent(),
        ),
      ),
    );
  }

  Widget _buildMarkdownContent() {
    print(
      '[PRIVACY_POLICY] Building markdown, content length: ${_markdownContent.length}',
    );

    if (_markdownContent.isEmpty) {
      return const Center(
        child: Text(
          'No content available',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      );
    }

    // Parse markdown manually since we don't have flutter_markdown package
    final lines = _markdownContent.split('\n');
    final widgets = <Widget>[];

    print('[PRIVACY_POLICY] Number of lines: ${lines.length}');

    for (var line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Handle headers
      if (line.startsWith('# ')) {
        widgets.add(_buildHeader(line.substring(2), 24, FontWeight.bold));
      } else if (line.startsWith('## ')) {
        widgets.add(_buildHeader(line.substring(3), 20, FontWeight.bold));
      } else if (line.startsWith('### ')) {
        widgets.add(_buildHeader(line.substring(4), 18, FontWeight.w600));
      } else if (line.startsWith('#### ')) {
        widgets.add(_buildHeader(line.substring(5), 16, FontWeight.w600));
      }
      // Handle bullet points
      else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        final text = line.trim().startsWith('- ')
            ? line.trim().substring(2)
            : line.trim().substring(2);
        // Check if bullet point has bold text
        if (text.contains('**')) {
          widgets.add(_buildFormattedBullet(text));
        } else {
          widgets.add(_buildBulletPoint(text));
        }
      }
      // Handle numbered lists
      else if (RegExp(r'^\d+\.').hasMatch(line.trim())) {
        final text = line.substring(line.indexOf('.') + 1).trim();
        widgets.add(_buildNumberedPoint(text));
      }
      // Handle bold text **text** or regular paragraph
      else {
        if (line.contains('**')) {
          widgets.add(_buildFormattedText(line));
        } else {
          widgets.add(_buildParagraph(line));
        }
      }
    }

    print('[PRIVACY_POLICY] Total widgets created: ${widgets.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildHeader(String text, double fontSize, FontWeight weight) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.7,
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedBullet(String text) {
    final parts = _parseFormattedText(text);

    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, height: 1.6),
                children: parts,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  List<TextSpan> _parseFormattedText(String text) {
    final parts = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    var lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        parts.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
      }
      // Add bold text
      parts.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      );
      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      parts.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return parts;
  }

  Widget _buildFormattedText(String text) {
    final parts = _parseFormattedText(text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, height: 1.7),
          children: parts,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
