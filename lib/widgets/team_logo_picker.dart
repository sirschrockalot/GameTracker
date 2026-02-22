import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/team_logo.dart';
import 'team_logo_avatar.dart';

/// Team logo selection: 8 suggestions + No logo. Apple-ish thin ring when selected.
class TeamLogoPicker extends StatelessWidget {
  const TeamLogoPicker({
    super.key,
    required this.teamName,
    required this.logoKind,
    this.templateId,
    this.paletteId,
    this.monogramText,
    required this.onSelect,
  });

  final String teamName;
  final String logoKind;
  final String? templateId;
  final String? paletteId;
  final String? monogramText;
  final void Function(String kind, String? templateId, String? paletteId, String? monogramText) onSelect;

  @override
  Widget build(BuildContext context) {
    final name = teamName.isEmpty ? 'Team' : teamName;
    final suggestions = logoSuggestionsForTeamName(name);
    const size = 48.0;
    const padding = 8.0;
    const recommendedLabelHeight = 20.0;
    final cellHeight = size + padding * 2 + recommendedLabelHeight;

    bool isSelected(LogoSuggestion s) {
      if (s.isMonogram) {
        return logoKind == kLogoKindMonogram && paletteId == s.paletteId && monogramText == s.monogramText;
      }
      return logoKind == kLogoKindTemplate && templateId == s.templateId && paletteId == s.paletteId;
    }

    Widget wrapSelect(Widget child, VoidCallback onTap, {required bool selected}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: size + padding * 2,
          height: cellHeight,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.primaryOrange : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(child: child),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Team logo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 4,
          runSpacing: 8,
          children: [
            ...suggestions.map((s) {
              final selected = isSelected(s);
              final avatar = TeamLogoAvatar.forSuggestion(
                suggestion: s,
                teamName: name,
                size: size,
              );
              return wrapSelect(
                s.recommended
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          avatar,
                          const SizedBox(height: 2),
                          Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : avatar,
                () {
                  if (s.isMonogram) {
                    onSelect(kLogoKindMonogram, null, s.paletteId, s.monogramText);
                  } else {
                    onSelect(kLogoKindTemplate, s.templateId, s.paletteId, null);
                  }
                },
                selected: selected,
              );
            }),
            wrapSelect(
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.chipInactive,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups, color: AppColors.textSecondary, size: 24),
              ),
              () => onSelect(kLogoKindNone, null, null, null),
              selected: logoKind == kLogoKindNone,
            ),
          ],
        ),
      ],
    );
  }
}
