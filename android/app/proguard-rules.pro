# Room loads generated database classes by name, which R8 would otherwise
# remove. WorkManager (pulled in by Firebase / ML Kit) crashed on launch
# without this.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
