import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'appproviders.dart';


class OctoSwitch extends ConsumerWidget {
  const OctoSwitch({
    required this.value,
    this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, ref) {
    return NeumorphicSwitch(
      value: value,
      onChanged: onChanged,
    );
  }
}

class OctoButton extends StatelessWidget {
  const OctoButton(
      String this.label, {
        this.fontSize = 20,
        this.onPressed,
        this.margin=10,
        this.tooltip,
        super.key,
      });

  final double fontSize;
  final String label;
  final NeumorphicButtonClickListener? onPressed;
  final String? tooltip;
  final double margin;
  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(tooltip: tooltip,
        margin: EdgeInsets.all(margin),
        pressed: null,
        onPressed: onPressed,
        child: Center(
          child: OctoText(
            label,
            fontSize,
            disabled: onPressed == null,
          ),
        ));
  }
}

class OctoText extends ConsumerWidget {
  const OctoText(
      this.text,
      this.size, {
        this.disabled = false,
        super.key,
      });

  final String text;
  final double size;
  final bool disabled;

  @override
  Widget build(BuildContext context, ref) {
    final darkMode = ref.watch(darkModeProvider);

    if (disabled & darkMode) {
      return NeumorphicText(
        text,
        style: NeumorphicStyle(
          intensity: 0.3,
        ),
        textStyle:
        NeumorphicTextStyle(fontSize: size, fontWeight: FontWeight.bold),
      );
    } else if (darkMode) {
      return NeumorphicText(
        text,
        textStyle:
        NeumorphicTextStyle(fontSize: size, fontWeight: FontWeight.bold),
      );
    } else if (disabled) {
      return NeumorphicText(
        text,
        style: NeumorphicStyle(
          depth: 0.5,
          intensity: 0.9,
        ),
        textStyle:
        NeumorphicTextStyle(fontSize: size, fontWeight: FontWeight.bold),
      );
    } else {
      return NeumorphicText(
        text,
        style: NeumorphicStyle(
          depth: 4,
          intensity: 1,
          surfaceIntensity: .01,
          color: Colors.white,
        ),
        textStyle:
        NeumorphicTextStyle(fontSize: size, fontWeight: FontWeight.bold),
      );
    }
  }
}

class InputBox extends StatelessWidget {
  const InputBox(this.label, this.controller,
      {required this.sharedPrefKey,
        required this.ref,
        this.password = false,
        this.maxLength,
        this.onChanged,
        super.key});

  final String label;
  final int? maxLength;
  final sharedPrefKey;
  final TextEditingController controller;
  final WidgetRef ref;
  final bool password;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      Flexible(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
              height: 50,
              child: TextField(
                maxLength: maxLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                maxLines: 1,
                obscureText: password,
                onChanged: onChanged,
                controller: controller,
                decoration: InputDecoration(
                  contentPadding:
                  EdgeInsets.only(left: 8, right: 8), // Removes padding
                  labelText: label,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 1),
                  ),
                ),
              )),
        ),
      ),
    ]);
  }
}

class OctoSlider extends ConsumerWidget {
  const OctoSlider({
    bool this.enabled = true,
    this.onChange,
    this.onChangeEnd,
    required this.value,
    super.key,
  });

  final double value;
  final bool enabled;
  final NeumorphicSliderListener? onChange;
  final NeumorphicSliderListener? onChangeEnd;

  @override
  Widget build(BuildContext context, ref) {
    return NeumorphicSlider(
      style: enabled
          ? (ref.watch(darkModeProvider)
          ? SliderStyle(
          accent: Colors.black,
          variant: Colors.black,
          lightSource: LightSource.bottomLeft,
          depth: 4)
          : SliderStyle(
          accent: Colors.white,
          variant: Colors.grey,
          lightSource: LightSource.bottomLeft,
          depth: 4))
          : (ref.watch(darkModeProvider)
          ? SliderStyle(
          border: NeumorphicBorder(
              isEnabled: true, width: 2, color: Color(0x11111111)),
          disableDepth: true,
          accent: Colors.black26,
          variant: Colors.black26,
          lightSource: LightSource.bottomLeft,
          depth: 4)
          : SliderStyle(
          border: NeumorphicBorder(
              isEnabled: true, width: 2, color: Color(0xEEEEEEEE)),
          disableDepth: true,
          accent: Colors.white,
          variant: Colors.white,
          lightSource: LightSource.bottomLeft,
          depth: 4)),
      max: 255,
      min: 1,
      value: value,
      onChanged: onChange,
      onChangeEnd: onChangeEnd,
    );
  }
}
