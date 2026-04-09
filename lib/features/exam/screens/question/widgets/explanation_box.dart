import 'package:flutter/material.dart';
import 'package:matricmate/features/exam/screens/question/widgets/language_toggle.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ExplanationBox extends StatelessWidget {
  const ExplanationBox({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedLang = "EN";
    final dark = AppHelperFuntions.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.darkerGrey.withValues(alpha: 0.5)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Language Toggle (Top Right)
          Positioned(top: 0, right: 0, child: LanguageToggle()),
          // Explanation text
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Text(
              selectedLang == "AM"
                  ? " Use Hansen's bearing-capacity equation for current practice due to its comprehensive correction factors and compatibility with measured cu/φ and modern design codes. Use Hansen's bearing-capacity equation for current practice due to its comprehensive correction factors and compatibility with measured cu/φ and modern design codes. Use Hansen's bearing-capacity equation for current practice due to its comprehensive correction factors and compatibility with measured cu/φ and modern design codes. Use Hansen's bearing-capacity equation for current practice due to its comprehensive correction factors and compatibility with measured cu/φ and modern design codes."
                  : "የሀንሰን የመሬት ግፊት መጠን ስሌት በዘመናዊ ስራ ላይ በስፋት ይጠቀማል ምክንያቱም የተለያዩ ማስተካከያ ፋክተሮችን ይካተታል እና ከመደበኛ የመለኪያ እሴቶች ጋር ይጣጣማል። የሀንሰን የመሬት ግፊት መጠን ስሌት በዘመናዊ ስራ ላይ በስፋት ይጠቀማል ምክንያቱም የተለያዩ ማስተካከያ ፋክተሮችን ይካተታል እና ከመደበኛ የመለኪያ እሴቶች ጋር ይጣጣማል። የሀንሰን የመሬት ግፊት መጠን ስሌት በዘመናዊ ስራ ላይ በስፋት ይጠቀማል ምክንያቱም የተለያዩ ማስተካከያ ፋክተሮችን ይካተታል እና ከመደበኛ የመለኪያ እሴቶች ጋር ይጣጣማል። የሀንሰን የመሬት ግፊት መጠን ስሌት በዘመናዊ ስራ ላይ በስፋት ይጠቀማል ምክንያቱም የተለያዩ ማስተካከያ ፋክተሮችን ይካተታል እና ከመደበኛ የመለኪያ እሴቶች ጋር ይጣጣማል።",
              textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
