CREATE TABLE [dbo].[EquipmentTypes] (
    [ID]                        INT           NOT NULL,
    [Description]               VARCHAR (255) NOT NULL,
    [EquipmentSubTypeID]        INT           NULL,
    [DefaultSpecification]      FLOAT (53)    NULL,
    [DefaultTolerance]          FLOAT (53)    NULL,
    [DefaultAlarmThreshold]     FLOAT (53)    NULL,
    [DefaultLowSpecification]   FLOAT (53)    NULL,
    [DefaultHighSpecification]  FLOAT (53)    NULL,
    [DefaultLowAlarmThreshold]  FLOAT (53)    NULL,
    [DefaultHighAlarmThreshold] FLOAT (53)    NULL,
    [CanRaiseAlarm]             BIT           DEFAULT (1) NOT NULL,
    [AlarmRaiseLowThreshold]    FLOAT (53)    DEFAULT ((-10)) NOT NULL,
    [AlarmRaiseHighThreshold]   FLOAT (53)    DEFAULT ((25)) NOT NULL,
    CONSTRAINT [PK_EquipmentTypes] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_EquipmentTypes_EquipmentSubTypes] FOREIGN KEY ([EquipmentSubTypeID]) REFERENCES [dbo].[EquipmentSubTypes] ([ID]),
    CONSTRAINT [UX_EquipmentTypes] UNIQUE NONCLUSTERED ([Description] ASC) WITH (FILLFACTOR = 90)
);

