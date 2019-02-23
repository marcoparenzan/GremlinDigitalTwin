--
--	Creating a Digital Twin with Azure Sql Database
-- SQL Saturday Pordenone 2019- Feb 23rd, 2019
--

--
-- creating nodes and edges
--

CREATE TABLE dbo.Topology (
       Id INTEGER PRIMARY KEY IdENTITY(1,1), 
       [Name] nVARCHAR(64), 
       [Type] nVARCHAR(64)
) AS NODE;

CREATE TABLE dbo.Devices (
       Id INTEGER PRIMARY KEY IdENTITY(1,1), 
       [Name] nVARCHAR(64), 
       [Type] nVARCHAR(64)
) AS NODE;

CREATE TABLE dbo.TopologyEdges (
       Id INTEGER PRIMARY KEY IdENTITY(1,1)
) AS Edge;

CREATE TABLE dbo.DeviceEdges (
       Id INTEGER PRIMARY KEY IdENTITY(1,1)
) AS Edge;

--
-- adding values
--
delete from dbo.Topology
delete from dbo.TopologyEdges
delete from dbo.Devices
delete from dbo.DeviceEdges

-- modeling nodes as 

exec dbo.AddTopology '', 'House01', 'Venue', 'Consumer'
exec dbo.AddTopology 'House01','Basement', 'Floor', 'Basement'
exec dbo.AddTopology 'House01-Basement','Garage', 'Room', 'Garage'

exec dbo.AddDevice 'House01-Basement', 'Central'
exec dbo.AddSensor 'House01-Basement-Central', 'Temperature1', 'Temperature'

exec dbo.AddTopology 'House01','Floor1', 'Floor', 'Generic'
exec dbo.AddTopology 'House01-Floor1', 'Bath', 'Room', 'Bath'

exec dbo.AddDevice 'House01-Floor1-Bath', 'Central'
exec dbo.AddSensor 'House01-Floor1-Bath-Central', 'Temperature1', 'Temperature'
exec dbo.AddSensor 'House01-Floor1-Bath-Central', 'Humidity1', 'Humidity'

exec dbo.AddTopology 'House01-Floor1','Kitchen', 'Room', 'Kitchen'
exec dbo.AddTopology 'House01-Floor1','LivingRoom', 'Room', 'LivingRoom'
exec dbo.AddTopology 'House01','Floor2', 'Floor', 'Generic'
exec dbo.AddTopology 'House01-Floor2','Bath', 'Room', 'Bath'

exec dbo.AddDevice 'House01-Floor2-Bath', 'Central'
exec dbo.AddSensor 'House01-Floor2-Bath-Central', 'Temperature1', 'Temperature'
exec dbo.AddSensor 'House01-Floor2-Bath-Central', 'Humidity1', 'Humidity'

exec dbo.AddTopology 'House01-Floor2','Bedroom1', 'Room', 'BedRoom'
exec dbo.AddTopology 'House01-Floor2','Bedroom2', 'Room', 'BedRoom'

exec dbo.AddTopology '', 'Office02', 'Venue', 'Business'
exec dbo.AddTopology 'Office02','Bath1', 'Room', 'Bath'

exec dbo.AddDevice 'Office02-Bath1', 'Central'
exec dbo.AddSensor 'Office02-Bath1-Central', 'Temperature1', 'Temperature'
exec dbo.AddSensor 'Office02-Bath1-Central', 'Humidity1', 'Humidity'

exec dbo.AddTopology 'Office02','Bath2', 'Room', 'Bath'
exec dbo.AddTopology 'Office02','Office1', 'Room', 'Office'
exec dbo.AddTopology 'Office02','Office2', 'Room', 'Bath'

exec dbo.AddTopology '', 'House03', 'Venue', 'Consumer'
exec dbo.AddTopology 'House03','Basement', 'Floor', 'Basement'
exec dbo.AddTopology 'House03-Basement','Bath1', 'Room', 'Bath'

exec dbo.AddDevice 'House03-Basement-Bath1', 'Central'
exec dbo.AddSensor 'House03-Basement-Bath1-Central', 'Temperature1', 'Temperature'
exec dbo.AddSensor 'House03-Basement-Bath1-Central', 'Humidity1', 'Humidity'

exec dbo.AddTopology 'House03-Basement','Garage1', 'Room', 'Garage'
exec dbo.AddTopology 'House03-Basement','Garage2', 'Room', 'Garage'
exec dbo.AddTopology 'House03','Floor1', 'Floor', 'Generic'
exec dbo.AddTopology 'House03-Floor1','Bath1', 'Room', 'Bath'
exec dbo.AddTopology 'House03-Floor1','Kitchen', 'Room', 'Kitchen'
exec dbo.AddTopology 'House03-Floor1','LivingRoom', 'Room', 'LivingRoom'

exec dbo.AddDevice 'House03-Floor1-LivingRoom', 'Central'
exec dbo.AddSensor 'House03-Floor1-LivingRoom-Central', 'Lux1', 'Lux'

exec dbo.AddTopology 'House03-Floor1','Bath2', 'Room', 'Bath'
exec dbo.AddTopology 'House03-Floor1','Bedroom1', 'Room', 'BedRoom'

exec dbo.AddDevice 'House03-Floor1-Bedroom1', 'Central'
exec dbo.AddSensor 'House03-Floor1-Bedroom1-Central', 'Temperature1', 'Temperature'
exec dbo.AddSensor 'House03-Floor1-Bedroom1-Central', 'Lux1', 'Lux'

exec dbo.AddDevice 'House03-Floor1-Bath1', 'Central'
exec dbo.AddSensor 'House03-Floor1-Bath1-Central', 'Temperature1', 'Temperature'
exec dbo.AddSensor 'House03-Floor1-Bath1-Central', 'Humidity1', 'Humidity'

exec dbo.AddDevice 'House03-Floor1-Bath2', 'Central'
exec dbo.AddSensor 'House03-Floor1-Bath2-Central', 'Temperature1', 'Temperature'
exec dbo.AddSensor 'House03-Floor1-Bath2-Central', 'Humidity1', 'Humidity'


--
-- sp
--

CREATE PROCEDURE [dbo].[AddTopology]
(
    @Base nvarchar(64), @Name nvarchar(64), @Type nvarchar(64), @SubType nvarchar(64)
)
AS
BEGIN

	DECLARE @fullname nvarchar(64)
	IF @Base = ''
		SET @FullName = @Name
	ELSE
		SET @FullName = @Base + '-' + @Name

    INSERT dbo.Topology (Name, Type, SubType) VALUES (@FullName, @Type, @SubType)

	IF (@Base <> '')
	BEGIN
			INSERT dbo.TopologyEdges VALUES (
			(SELECT $node_id FROM dbo.Topology WHERE Name = @Base),
			(SELECT $node_id FROM dbo.Topology WHERE Name = @FullName)
		)
	END
END

CREATE PROCEDURE [dbo].[AddDevice]
(
    @Base nvarchar(64), @Name nvarchar(64), @SubType nvarchar(64) = 'Base'
)
AS
BEGIN

	DECLARE @fullname nvarchar(64)
	SET @FullName = @Base + '-' + @Name

    INSERT dbo.Devices (Name, Type, SubType) VALUES (@FullName, 'Device', @SubType)

	INSERT dbo.DeviceEdges VALUES (
		(SELECT $node_id FROM dbo.Topology WHERE Name = @Base),
		(SELECT $node_id FROM dbo.Devices WHERE Name = @FullName)
	)
END


CREATE PROCEDURE [dbo].[AddSensor]
(
    @Base nvarchar(64), @Name nvarchar(64), @SubType nvarchar(64)
)
AS
BEGIN

	DECLARE @fullname nvarchar(64)
	SET @FullName = @Base + '-' + @Name

    INSERT dbo.Devices (Name, Type, SubType) VALUES (@FullName, 'Sensor', @SubType)

	INSERT dbo.DeviceEdges VALUES (
		(SELECT $node_id FROM dbo.Devices WHERE Name = @Base),
		(SELECT $node_id FROM dbo.Devices WHERE Name = @FullName)
	)
END

--
-- queries
--

SELECT * FROM Topology

SELECT * FROM TopologyEdges

SELECT * FROM Devices

SELECT * FROM DeviceEdges

-- some matches

select t1.type, t2.type, t3.type, t3.name
from Topology t1, TopologyEdges e1, Topology t2, TopologyEdges e2, Topology t3
WHERE MATCH(t1-(e1)->t2-(e2)->t3)

select t1.type, t2.type, t2.name
from Topology t1, TopologyEdges e1, Topology t2
WHERE MATCH(t1-(e1)->t2)

SELECT t.Name, d2.*
FROM Topology t, DeviceEdges, Devices d, DeviceEdges e2, Devices d2
WHERE MATCH (t-(DeviceEdges)->d-(e2)->d2)
AND d2.SubType = 'Temperature'

SELECT t1.*
--Topology t1, TopologyEdges e1, 
--t1-(e1)->
FROM Topology t, DeviceEdges, Devices d, DeviceEdges e2, Devices d2
WHERE MATCH (t-(DeviceEdges)->d-(e2)->d2)
