import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:kt_dart/src/collection/kt_list.dart';
import 'package:dartz/dartz.dart';
import 'package:note_app/domain/notes/i_note_repository.dart';
import 'package:note_app/domain/notes/note_failure.dart';
import 'package:note_app/domain/notes/note.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:note_app/infrastructure/core/firestore_helpers.dart';
import 'package:note_app/infrastructure/notes/note_dtos.dart';
import 'package:kt_dart/kt.dart';
import 'package:rxdart/rxdart.dart';

@LazySingleton(as: INoteRepository)
class NoteRepository implements INoteRepository {
  final FirebaseFirestore _firestore;

  NoteRepository(this._firestore);

  @override
  Stream<Either<NoteFailure, KtList<Note>>> watchAll() async* {
    final userDoc = await _firestore.userDocument();
    yield* userDoc.noteCollection
        .orderBy('serverTimeStamp', descending: true)
        .snapshots()
        .map((snapshot) => right<NoteFailure, KtList<Note>>(snapshot.docs
            .map((doc) => NoteDto.fromFirestore(doc).toDomain())
            .toImmutableList()))
        .onErrorReturnWith((e, stackTrace) {
      if (e is PlatformException && e.message!.contains('permission-denied')) {
        return left(const NoteFailure.insufficientPermission());
      } else {
        // log.error(e.toString());
        return left(const NoteFailure.unexpected());
      }
    });
  }

  /* 
     doc as DocumentSnapshot<Map<String, dynamic>>
    
     replace it if above statement not working

     Map<String, dynamic> data() {
    return _CodecUtility.replaceDelegatesWithValueInMap(
        _delegate.data(), _firestore);
  }
   */

  @override
  Stream<Either<NoteFailure, KtList<Note>>> watchUncompleted() async* {
    final userDoc = await _firestore.userDocument();
    yield* userDoc.noteCollection
        .orderBy('serverTimeStamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => NoteDto.fromFirestore(doc).toDomain()),
        )
        .map(
          (notes) => right<NoteFailure, KtList<Note>>(
            notes
                .where((note) =>
                    note.todos.getOrCrash().any((todoItem) => !todoItem.done))
                .toImmutableList(),
          ),
        )
        .onErrorReturnWith((e, stackTrace) {
      if (e is PlatformException && e.message!.contains('permission-denied')) {
        return left(const NoteFailure.insufficientPermission());
      } else {
        // log.error(e.toString());
        return left(const NoteFailure.unexpected());
      }
    });
  }

  @override
  Future<Either<NoteFailure, Unit>> create(Note note) {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  Future<Either<NoteFailure, Unit>> delete(Note note) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<Either<NoteFailure, Unit>> update(Note note) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
