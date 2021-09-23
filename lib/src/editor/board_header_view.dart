import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_crash/src/editor/model.dart';

class BoardHeaderView extends StatelessWidget {
  const BoardHeaderView({
    Key? key,
    required this.board,
    this.onNameChanged,
    this.onDescriptionChanged,
  }) : super(key: key);

  final BoardDetails board;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            const SizedBox(
              height: 272,
              width: double.infinity,
              child: FlutterLogo(),
            ),
            Positioned(
              top: 252,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  color: Colors.white,
                ),
                width: MediaQuery.of(context).size.width,
                height: 20,

                ///grabber tab
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 48.0,
                    height: 2.0,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                      color: Color(0x0f000000),
                      borderRadius: BorderRadius.all(
                        Radius.circular(5.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: board.name ?? '',
                  onChanged: onNameChanged,
                  cursorWidth: 3,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.text,
                  maxLines: null,
                  cursorColor: const Color(0xff313131),
                  style: const TextStyle(
                    color: Color(0xff313131),
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    fontFamily: 'Work Sans',
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(0, 16, 0, 0),
                    isCollapsed: true,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: 'Untitled',
                    hintStyle: TextStyle(
                      color: Color(0xffcfcfcf),
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      fontFamily: 'Work Sans',
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty != false) {
                      return 'Missing title';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TextFormField(
            initialValue: board.description,
            onChanged: onDescriptionChanged,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            cursorHeight: 20,
            cursorWidth: 1,
            cursorColor: const Color(0xff313131),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xffb1b1b1),
              fontFamily: 'Roboto',
              height: 1.4,
              letterSpacing: 0.15,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: '+ add a description',
              hintStyle: TextStyle(
                fontSize: 14,
                color: const Color(0xff313131).withOpacity(0.38),
                fontFamily: 'Roboto',
                height: 1.4,
                letterSpacing: 0.15,
              ),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return '+ add a description';
              }
              return null;
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 0, 8),
          color: const Color(0xfff2f2f2),
          height: 1,
        ),
      ],
    );
  }
}
