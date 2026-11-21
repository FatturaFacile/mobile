// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manufacturing_dao.dart';

// ignore_for_file: type=lint
mixin _$ManufacturingDaoMixin on DatabaseAccessor<AppDatabase> {
  $MfgLocalWorkCentersTable get mfgLocalWorkCenters =>
      attachedDatabase.mfgLocalWorkCenters;
  $MfgLocalMachinesTable get mfgLocalMachines =>
      attachedDatabase.mfgLocalMachines;
  $MfgLocalRoutingsTable get mfgLocalRoutings =>
      attachedDatabase.mfgLocalRoutings;
  $MfgLocalRoutingStepsTable get mfgLocalRoutingSteps =>
      attachedDatabase.mfgLocalRoutingSteps;
  $MfgLocalOeeSummariesTable get mfgLocalOeeSummaries =>
      attachedDatabase.mfgLocalOeeSummaries;
  ManufacturingDaoManager get managers => ManufacturingDaoManager(this);
}

class ManufacturingDaoManager {
  final _$ManufacturingDaoMixin _db;
  ManufacturingDaoManager(this._db);
  $$MfgLocalWorkCentersTableTableManager get mfgLocalWorkCenters =>
      $$MfgLocalWorkCentersTableTableManager(
        _db.attachedDatabase,
        _db.mfgLocalWorkCenters,
      );
  $$MfgLocalMachinesTableTableManager get mfgLocalMachines =>
      $$MfgLocalMachinesTableTableManager(
        _db.attachedDatabase,
        _db.mfgLocalMachines,
      );
  $$MfgLocalRoutingsTableTableManager get mfgLocalRoutings =>
      $$MfgLocalRoutingsTableTableManager(
        _db.attachedDatabase,
        _db.mfgLocalRoutings,
      );
  $$MfgLocalRoutingStepsTableTableManager get mfgLocalRoutingSteps =>
      $$MfgLocalRoutingStepsTableTableManager(
        _db.attachedDatabase,
        _db.mfgLocalRoutingSteps,
      );
  $$MfgLocalOeeSummariesTableTableManager get mfgLocalOeeSummaries =>
      $$MfgLocalOeeSummariesTableTableManager(
        _db.attachedDatabase,
        _db.mfgLocalOeeSummaries,
      );
}
