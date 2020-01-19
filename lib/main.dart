import 'dart:js';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/hiveDB.dart';
import 'code/config.dart';



void main() async{
  if(!kIsWeb){
    await Hive.initFlutter();
  }


Hive.registerAdapter(NoteAdapter());
Hive.registerAdapter(NoteTypeAdapter());
Hive.registerAdapter(CheckListNoteAdapter());
Hive.registerAdapter(TextNoteAdapter());

await Hive.openBox<Note>(noteBox);
await Hive.openBox<TextNote>(textNoteBox);
await Hive.openBox<CheckListNote>(checkListNotesBox);

runApp(MyApp());

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      title: appName,
      home: Scaffold(
        appBar: AppBar(
          title: Text(appName),
        ),
        body: getNotes(), 
        floatingActionButton: addNoteButton(),
      ),
    );
  }
}
getNotes() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Note>(notesBox).listenable(),
      builder: (context, Box<Note> box, _) {
        if (box.values.isEmpty) {
          return Center(
            child: Text("No Notes!"),
          );
        }
        List<Note> notes = getNotesList(); //get notes from box function
        return ReorderableListView(
            onReorder: (oldIndex, newIdenx) async {
              await reorderNotes(oldIndex, newIdenx, notes);
            },
            children: <Widget>[
              for (Note note in notes) ...[
                getNoteInfo(note, context),
              ],
            ]);
      },
    );
}
getNoteList(){
  List<Note>notes=Hive.box<Note>(notesBox).values.toList();
  notes=getNotesSortedByOrder(notes);

  return notes;
}

getNotesInfo(Note note){

  return ListTile(
    dense: true,
    key: Key(note.key.toString()),
    title: Text(note.title),
  );
}

reorderNotes(oldIndex, newIdenx, notes) async {
    Box<Note> hiveBox = Hive.box<Note>(notesBox);
    if (oldIndex < newIdenx) {
      notes[oldIndex].position = newIdenx - 1;
      await hiveBox.put(notes[oldIndex].key, notes[oldIndex]);
      for (int i = oldIndex + 1; i < newIdenx; i++) {
        notes[i].position = notes[i].position - 1;
        await hiveBox.put(notes[i].key, notes[i]);
      }
    } else {
      notes[oldIndex].position = newIdenx;
      await hiveBox.put(notes[oldIndex].key, notes[oldIndex]);
      for (int i = newIdenx; i < oldIndex; i++) {
        notes[i].position = notes[i].position + 1;
        await hiveBox.put(notes[i].key, notes[i]);
      }
    }
  }

  addNoteButton(){
    return Builder(builder: (context){
      return FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: (){
            Navigator.of(context).push(MaterialPageRoute(builder: (context)=>AddNote()));
          },
      );
    });
  }

    createTextNote(BuildContext context) async {
    if (_formKey.currentState.validate()) {
      Box<Note> notes = Hive.box<Note>(notesBox);
      reorderNotes(notes);
      int pk = await notes.add(Note(DateTime.now(), _titleController.text,
          _descriptionController.text, DateTime.now(), NoteType.Text, 0));
      Box<TextNote> tNotes = Hive.box<TextNote>(textNotesBox);
      await tNotes.add(TextNote("", pk));
      Navigator.of(context).pop();
    }
  }

createCheckListNote(BuildContext context) async {
    if (_formKey.currentState.validate()) {
      Box<Note> notes = Hive.box<Note>(notesBox);
      reorderNotes(notes);
      int pk = await notes.add(Note(DateTime.now(), _titleController.text,
          _descriptionController.text, DateTime.now(), NoteType.CheckList, 0));
      Box<CheckListNote> clNotes = Hive.box<CheckListNote>(checkListNotesBox);
      await clNotes.add(CheckListNote("", false, 0, pk));
      Navigator.of(context).pop();
    }
  }

  reorderNotes(Box<Note> notes) {
    for (Note noteOrder in notes.values) {
      noteOrder.position = noteOrder.position + 1;
      notes.put(noteOrder.key, noteOrder);
    }
  }

getNoteInfo(Note note,BuildContext context){

  return ListTile(
    dense: true,
    key:  Key(note.key.toString()),
    onTap: (){

      if(note.noteType==NoteType.text){
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context)=>EditTextNote(
              noteParent:note.key,
              noteTitle:note.title,
            ),
          ),
        );
      }else{
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:(context)=>EditCheckNote(
              noteParent:note.key,
              noteTitle:note.title,
            ),
          ),
        );
      }
    },
    title: Container(
      padding: EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0);
        color: Colors.black,
      ),
      child: Text(
        note.title,
        style: TextStyle(
          fontSize: 18
        ),
      ),
    ),
  );

}