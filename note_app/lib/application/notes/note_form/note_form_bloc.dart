import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:kt_dart/kt.dart';
import 'package:meta/meta.dart';
import 'package:note_app/domain/notes/i_note_repository.dart';
import 'package:note_app/domain/notes/note.dart';
import 'package:note_app/domain/notes/note_failure.dart';
import 'package:note_app/domain/notes/value_objects.dart';
import 'package:note_app/presentation/notes/note_form/misc/todo_item_presentation_classes.dart';

part 'note_form_event.dart';
part 'note_form_state.dart';
part 'note_form_bloc.freezed.dart';

@injectable
class NoteFormBloc extends Bloc<NoteFormEvent, NoteFormState> {
  final INoteRepository _noteRepository;

  NoteFormBloc(this._noteRepository) : super(NoteFormState.initial()) {
    on<NoteFormEvent>((event, emit) async {
      await event.map<FutureOr<void>>(
        initialized: (e) async {
          emit(e.initialNoteOption.fold(
            () => state,
            (initialNote) => state.copyWith(
              note: initialNote,
              isEditing: true,
            ),
          ));
        },
        bodyChanged: (e) async {
          emit(state.copyWith(
            note: state.note.copyWith(body: NoteBody(e.bodyStr)),
            saveFailureOrSuccessOption: none(),
          ));
        },
        colorChanged: (e) async {
          emit(state.copyWith(
            note: state.note.copyWith(color: NoteColor(e.color)),
            saveFailureOrSuccessOption: none(),
          ));
        },
        todosChanged: (e) async {
          emit(state.copyWith(
            note: state.note.copyWith(
              todos: List3(e.todos.map((primitive) => primitive.toDomain())),
            ),
            saveFailureOrSuccessOption: none(),
          ));
        },
        saved: (e) async {
          Either<NoteFailure, Unit>? failureOrSuccess;

          emit(state.copyWith(
            isSaving: true,
            saveFailureOrSuccessOption: none(),
          ));

          if (state.note.failureOption.isNone()) {
            failureOrSuccess = state.isEditing
                ? await _noteRepository.update(state.note)
                : await _noteRepository.create(state.note);
          }

          emit(state.copyWith(
            isSaving: false,
            showErrorMessages: AutovalidateMode.always,
            saveFailureOrSuccessOption: optionOf(failureOrSuccess),
          ));
        },
      );
    });
  }
}
