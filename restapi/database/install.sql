DELETE FROM api_process_log WHERE event_handler_id IN (SELECT id FROM api_event_handler WHERE solution_id=10000);
DELETE FROM api_ui_app_nav_item WHERE solution_id=10000;
DELETE FROM api_ui_app WHERE solution_id=10000;
DELETE FROM api_table_view WHERE solution_id=10000;
DELETE FROM api_event_handler WHERE solution_id=10000;

INSERT IGNORE INTO api_solution(id,name) VALUES (10000, 'IoTSensorNet');

CREATE TABLE IF NOT EXISTS iot_location(
    id int NOT NULL AUTO_INCREMENT,
    name varchar(50) NOT NULL,
    local_gateway_url nvarchar(500) NULL COMMENT 'URL for iot Gateway',
    local_gateway_topic nvarchar(500) NULL COMMENT 'Topic for iot MQTT Gateway',
    local_gateway_protocol varchar(10) NOT NULL DEFAULT 'mqtt' COMMENT 'Protocol for messages',
    PRIMARY KEY(id),
    UNIQUE KEY(name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE iot_location ADD COLUMN IF NOT EXISTS local_gateway_url nvarchar(500) NULL COMMENT 'URL for iot Gateway';
ALTER TABLE iot_location ADD COLUMN IF NOT EXISTS local_gateway_topic nvarchar(500) NULL COMMENT 'Topic for iot MQTT Gateway';
ALTER TABLE iot_location ADD COLUMN IF NOT EXISTS local_gateway_protocol varchar(10) NOT NULL DEFAULT 'mqtt' COMMENT 'Protocol for messages';

INSERT IGNORE INTO iot_location (id,name,local_gateway_url, local_gateway_topic) 
    VALUES (
        1,'DEFAULT','http://localhost:5001/$session_id$/$device$/$command$/$value$','/restapi/iot/local_gw'
        );


/* Aktoren */
#DROP TABLE IF EXISTS iot_device_attribute_value;
#DROP TABLE IF EXISTS iot_device_attribute;
#DROP TABLE IF EXISTS iot_device_routing;
#DROP TABLE IF EXISTS iot_device;
#DROP TABLE IF EXISTS iot_device_categorie_class_mapping;
#DROP TABLE IF EXISTS iot_device_class;
#DROP TABLE IF EXISTS iot_device_vendor;
#DROP TABLE IF EXISTS iot_device_status;

CREATE TABLE IF NOT EXISTS iot_device_vendor(
    id nvarchar(50) NOT NULL,
    name nvarchar(50) NOT NULL,
    PRIMARY KEY(id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_device_vendor(id, name) VALUES ('tuya','Tuya');
INSERT IGNORE INTO iot_device_vendor(id, name) VALUES ('shelly','Shelly');
INSERT IGNORE INTO iot_device_vendor(id, name) VALUES ('dk9mbs','DK9MBS Aktor Node');

CREATE TABLE IF NOT EXISTS iot_device_class(
    id nvarchar(50) NOT NULL,
    name nvarchar(50) NOT NULL,
    PRIMARY KEY(id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_device_class(id, name) VALUES ('Bulb','Bulb');
INSERT IGNORE INTO iot_device_class(id, name) VALUES ('Outlet','Wall outlet');
INSERT IGNORE INTO iot_device_class(id, name) VALUES ('shellyplus1','Shelly Relais, 1 Kanal 16A');
INSERT IGNORE INTO iot_device_class(id, name) VALUES ('dk9mbs_io_node','DK9MBS Aktor Node');

CREATE TABLE IF NOT EXISTS iot_device_status (
    id varchar(50) NOT NULL,
    name varchar(50) NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_device_status(id,name) VALUES ('new','New');
INSERT IGNORE INTO iot_device_status(id,name) VALUES ('active','Active');
INSERT IGNORE INTO iot_device_status(id,name) VALUES ('disabled','Disabled');

CREATE TABLE IF NOT EXISTS iot_device(
    id varchar(250) NOT NULL,
    name varchar(250) NOT NULL,
    product_id nvarchar(250) NULL,
    product_name nvarchar(250) NULL,
    address nvarchar(50) NOT NULL,
    local_key nvarchar(100) NULL,
    version nvarchar(50) NOT NULL DEFAULT '0',
    version_available varchar(50) NULL,
    class_id varchar(50) NULL,
    category varchar(50) NULL,
    vendor_id nvarchar(50) NOT NULL,
    status_id nvarchar(50) NOT NULL DEFAULT 'new',
    location_id int NOT NULL DEFAULT '1',
    icon nvarchar(250) NULL,
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    last_scan_on timestamp NULL,
    network_ssid varchar(250) NULL,
    network_rssi int NOT NULL DEFAULT '0',
    PRIMARY KEY(id),
    FOREIGN KEY(status_id) REFERENCES iot_device_status(id),
    FOREIGN KEY(class_id) REFERENCES iot_device_class(id),
    FOREIGN KEY(vendor_id) REFERENCES iot_device_vendor(id),
    FOREIGN KEY(location_id) REFERENCES iot_location(id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE iot_device ADD COLUMN IF NOT EXISTS network_ssid varchar(250) NULL;
ALTER TABLE iot_device ADD COLUMN IF NOT EXISTS network_rssi int NOT NULL DEFAULT '0';
ALTER TABLE iot_device ADD COLUMN IF NOT EXISTS version_available varchar(50) NULL AFTER version;

CREATE TABLE IF NOT EXISTS iot_device_channel(
    id int NOT NULL AUTO_INCREMENT COMMENT 'Unique ID',
    name varchar(50) NOT NULL COMMENT 'Alias for the chanel',
    alias varchar(50) NULL COMMENT 'Alias for this channel',
    device_id varchar(250) NOT NULL COMMENT 'ID of the device',
    channel varchar(50) NOT NULL COMMENT 'Name of the device channel',
    channel_value varchar(50) NULL COMMENT 'Current value of the channel',
    PRIMARY KEY(id),
    FOREIGN KEY(device_id) REFERENCES iot_device(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE iot_device_channel ADD COLUMN IF NOT EXISTS alias varchar(50) NULL  COMMENT 'Alias for this channel' AFTER name;


CREATE TABLE IF NOT EXISTS iot_device_categorie_class_mapping(
    id int NOT NULL AUTO_INCREMENT COMMENT '',
    category nvarchar(50) NOT NULL,
    class_id nvarchar(50) NOT NULL COMMENT '',
    vendor_id nvarchar(50) NOT NULL COMMENT '',
    PRIMARY KEY(id),
    UNIQUE KEY(category, class_id, vendor_id),
    FOREIGN KEY(class_id) REFERENCES iot_device_class(id),
    FOREIGN KEY(vendor_id) REFERENCES iot_device_vendor(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE iot_device_categorie_class_mapping (category, class_id, vendor_id) VALUES ('cz','Outlet','tuya');
INSERT IGNORE iot_device_categorie_class_mapping (category, class_id, vendor_id) VALUES ('dj','Bulb','tuya');

CREATE TABLE IF NOT EXISTS iot_device_routing(
    id int NOT NULL AUTO_INCREMENT COMMENT '',
    internal_device_id nvarchar(250) NOT NULL COMMENT '',
    external_device_id nvarchar(250) NOT NULL COMMENT '',
    description varchar(50) NULL COMMENT 'description for this assignment',
    show_dashboard smallint NOT NULL DEFAULT '-1' COMMENT 'Show on Dashboard',
    dashboard_pos smallint NOT NULL DEFAULT '100' COMMENT 'Position on Dashboard',
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY(external_device_id) REFERENCES iot_device(id),
    PRIMARY KEY(id),
    UNIQUE KEY(internal_device_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE iot_device_routing ADD COLUMN IF NOT EXISTS show_dashboard smallint NOT NULL DEFAULT '-1' COMMENT 'Show on Dashboard';
ALTER TABLE iot_device_routing ADD COLUMN IF NOT EXISTS dashboard_pos smallint NOT NULL DEFAULT '100' COMMENT 'Position on Dashboard';

CREATE TABLE IF NOT EXISTS iot_device_attribute(
    id int NOT NULL AUTO_INCREMENT COMMENT 'Unique key',
    name nvarchar(100) NOT NULL COMMENT 'Name of the internal status',
    vendor_id nvarchar(50) NOT NULL COMMENT 'Vendor',
    class_id nvarchar(50) NULL COMMENT 'Device Class',
    device_attribute_key nvarchar(250) NOT NULL COMMENT 'The device internal attribute',
    is_boolean smallint NOT NULL default '0' COMMENT '',
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL COMMENT 'Created on',
    PRIMARY KEY(id),
    UNIQUE KEY(name, vendor_id, class_id),
    FOREIGN KEY(class_id) REFERENCES iot_device_class(id),
    FOREIGN KEY(vendor_id) REFERENCES iot_device_vendor(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_device_attribute (name, vendor_id,class_id, device_attribute_key, is_boolean) VALUES ('power','tuya','Bulb','20',-1);
INSERT IGNORE INTO iot_device_attribute (name, vendor_id,class_id, device_attribute_key, is_boolean) VALUES ('power','tuya','Outlet','1',-1);
INSERT IGNORE INTO iot_device_attribute (name, vendor_id,class_id, device_attribute_key, is_boolean) VALUES ('power','shelly','shellyplus1','on',-1);
INSERT IGNORE INTO iot_device_attribute (name, vendor_id,class_id, device_attribute_key, is_boolean) VALUES ('power','dk9mbs','dk9mbs_io_node','status',-1);

CREATE TABLE IF NOT EXISTS iot_device_attribute_value(
    id int NOT NULL AUTO_INCREMENT COMMENT '',
    device_id varchar(250) NOT NULL COMMENT '',
    device_attribute_id int NOT NULL COMMENT '',
    value varchar(250) NULL COMMENT '',
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL COMMENT 'Created on',
    UNIQUE KEY(device_id, device_attribute_id),
    PRIMARY KEY(id),
    FOREIGN KEY(device_id) REFERENCES iot_device(id),
    FOREIGN KEY(device_attribute_id) REFERENCES iot_device_attribute(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/* Ende Aktoren */

CREATE TABLE IF NOT EXISTS iot_node_status(
    id int NOT NULL,
    name varchar(50) NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_node_status(id, name) VALUES (10,'Active');
INSERT IGNORE INTO iot_node_status(id, name) VALUES (20,'Disabled');

CREATE TABLE IF NOT EXISTS iot_node (
    id int NOT NULL AUTO_INCREMENT,
    name varchar(250) NOT NULL,
    last_error_code int NULL,
    ip_address varchar(50) NULL,
    last_heard_on timestamp NULL,
    status_id int NOT NULL DEFAULT '0',
    location_id int NULL,
    display_template text NULL,
    version varchar(50) NULL,
    define_onewire smallint NOT NULL default '-1',
    define_dht smallint NOT NULL default '0',
    define_dht_type varchar(10) NOT NULL default 'DHT11',
    define_lightness smallint NOT NULL default '0',
    define_rainfall smallint NOT NULL default '0',
    define_display smallint NOT NULL default '-1',
    define_mqtt smallint NOT NULL default '0',
    define_http smallint NOT NULL default '-1',
    define_https smallint NOT NULL default '-1',
    define_ota smallint NOT NULL default '-1',
    define_bmp smallint NOT NULL default '0',
    define_espnow_sub smallint NOT NULL default '0',
    define_espnow_pub smallint NOT NULL default '0',
    define_mlx90614 smallint NOT NULL default '0',
    PRIMARY KEY(id),
    FOREIGN KEY(status_id) REFERENCES iot_node_status(id),
    FOREIGN KEY(location_id) REFERENCES iot_location(id),
    UNIQUE KEY(name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS location_id int NULL;
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS display_template text NULL;
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS version varchar(50) NULL AFTER display_template;
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_onewire smallint NOT NULL default '-1';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_dht smallint NOT NULL default '0';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_dht_type varchar(10) NOT NULL default 'DHT11';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_lightness smallint NOT NULL default '0';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_rainfall smallint NOT NULL default '0';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_display smallint NOT NULL default '-1';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_mqtt smallint NOT NULL default '0';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_http smallint NOT NULL default '-1';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_https smallint NOT NULL default '-1';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_ota smallint NOT NULL default '-1';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_bmp smallint NOT NULL default '0';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_espnow_sub smallint NOT NULL default '0';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_espnow_pub smallint NOT NULL default '0';
ALTER TABLE iot_node ADD COLUMN IF NOT EXISTS define_mlx90614 smallint NOT NULL default '0';
ALTER TABLE iot_node ADD CONSTRAINT  FOREIGN KEY IF NOT EXISTS (location_id) REFERENCES iot_location (id);

CREATE TABLE IF NOT EXISTS iot_sensor_data(
    id int NOT NULL AUTO_INCREMENT,
    sensor_id varchar(250) NOT NULL,
    sensor_namespace varchar(500) NOT NULL,
    sensor_value numeric(15,4) NOT NULL,
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(id),
    INDEX (sensor_id, created_on)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*
Start Archiv
*/
CREATE TABLE IF NOT EXISTS iot_sensor_data_archiv(
    id int NOT NULL,
    sensor_id varchar(250) NOT NULL,
    sensor_namespace varchar(500) NOT NULL,
    sensor_value numeric(15,4) NOT NULL,
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(id),
    INDEX (sensor_id, created_on)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*
Ende Archiv
*/

CREATE TABLE IF NOT EXISTS iot_sensor_type(
    id int NOT NULL,
    name varchar(50) NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_sensor_type (id, name) VALUES (1, 'DS 1820');
INSERT IGNORE INTO iot_sensor_type (id, name) VALUES (2, 'DHT 11');
INSERT IGNORE INTO iot_sensor_type (id, name) VALUES (3, 'DHT 22');
INSERT IGNORE INTO iot_sensor_type (id, name) VALUES (4, 'BMP180');
INSERT IGNORE INTO iot_sensor_type (id, name) VALUES (5, 'MLX 90614');
INSERT IGNORE INTO iot_sensor_type (id, name) VALUES (6, 'Taupunkt Berechnung');
INSERT IGNORE INTO iot_sensor_type (id, name) VALUES (7, 'DWD API');

CREATE TABLE IF NOT EXISTS iot_sensor (
    id varchar(250) NOT NULL COMMENT 'unique id',
    alias varchar(250) NOT NULL COMMENT 'sensor_id',
    description varchar(250) NOT NULL,
    last_value decimal(15,4) DEFAULT NULL,
    last_value_on datetime DEFAULT NULL,
    min_value decimal(15,4) NOT NULL DEFAULT 0.0000,
    max_value decimal(15,4) NOT NULL DEFAULT 0.0000,
    unit varchar(50) NOT NULL default 'unit',
    days_in_history int NOT NULL default '0' COMMENT 'auto delete in days',
    auto_delete_sensor_data smallint NOT NULL default '0' COMMENT '0=yes -1=no',
    watchdog_warning_sec int(11) DEFAULT NULL COMMENT 'Watchdog warnmeldungen wenn x sec. keine Nachricht',
    type_id int(11) DEFAULT NULL,
    notify smallint NOT NULL DEFAULT '-1' COMMENT 'Notify in case of watchdog errors',
    PRIMARY KEY(id),
    FOREIGN KEY (type_id) REFERENCES iot_sensor_type (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE iot_sensor ADD COLUMN IF NOT EXISTS type_id int NULL;
ALTER TABLE iot_sensor ADD CONSTRAINT  FOREIGN KEY IF NOT EXISTS (type_id) REFERENCES iot_sensor_type (id);
ALTER TABLE iot_sensor ADD COLUMN IF NOT EXISTS notify smallint NOT NULL DEFAULT '-1' COMMENT 'Notify in case of watchdog errors';

CREATE TABLE IF NOT EXISTS iot_sensor_routing_status(
    id int NOT NULL,
    name varchar(50) NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_sensor_routing_status(id, name) VALUES (0,'New');
INSERT IGNORE INTO iot_sensor_routing_status(id, name) VALUES (10,'Active');
INSERT IGNORE INTO iot_sensor_routing_status(id, name) VALUES (20,'Disabled');


CREATE TABLE IF NOT EXISTS iot_sensor_routing (
    id int NOT NULL AUTO_INCREMENT COMMENT 'unique id',
    internal_sensor_id varchar(250) NULL COMMENT 'sensorid for internal use',
    external_sensor_id varchar(250) NOT NULL COMMENT 'sensor id from a foreign network',
    description varchar(50) NULL COMMENT 'description for this assignment',
    status_id int NOT NULL default '0' COMMENT '0=new 1=enabled',
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    last_value_on timestamp NULL,
    PRIMARY KEY(id),
    UNIQUE KEY(external_sensor_id),
    FOREIGN KEY(status_id) REFERENCES iot_sensor_routing_status(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS iot_log_source (
    id int NOT NULL,
    name varchar(50) NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_log_source(id,name) VALUES (1,'Node');
INSERT IGNORE INTO iot_log_source(id,name) VALUES (2,'Node (Serial Debug)');
INSERT IGNORE INTO iot_log_source(id,name) VALUES (100,'System');

CREATE TABLE IF NOT EXISTS iot_log (
    id int NOT NULL AUTO_INCREMENT,
    name varchar(250) NOT NULL,
    message text NULL,
    source_id int NOT NULL,
    node_id int NULL COMMENT 'in case of source_id=1',
    node_name varchar(250) NULL COMMENT 'in case of source_id=1',
    ip_address varchar(50) NULL COMMENT 'in case of source_id=1',
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(source_id) REFERENCES iot_log_source(id),
    FOREIGN KEY(node_id) REFERENCES iot_node(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS iot_manual_sensor_data_status (
    id int NOT NULL,
    name varchar(50) NOT NULL,
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO iot_manual_sensor_data_status (id,name) VALUES (10,'New');
INSERT IGNORE INTO iot_manual_sensor_data_status (id,name) VALUES (20,'Processed');
INSERT IGNORE INTO iot_manual_sensor_data_status (id,name) VALUES (30,'Error');

CREATE TABLE IF NOT EXISTS iot_manual_sensor_data (
    id int NOT NULL AUTO_INCREMENT,
    name varchar(50) NOT NULL,
    external_sensor_id varchar(250) NOT NULL COMMENT 'External Sensor ID from iot_sensor_routing',
    value decimal(15,4) DEFAULT NULL,
    status_id int NOT NULL DEFAULT 10,
    error_text text NULL COMMENT 'In case of process error',
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(status_id) REFERENCES iot_manual_sensor_data_status(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS iot_sensor_change(
    id int NOT NULL AUTO_INCREMENT,
    change_subject varchar(250) NOT NULL,
    sensor_id varchar(250) NULL,
    change_date datetime NOT NULL,
    change_text text NULL,
    created_on timestamp default CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(sensor_id) REFERENCES iot_sensor(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS iot_dew_point_sensor(
    id int NOT NULL AUTO_INCREMENT COMMENT '',
    name varchar(100) NOT NULL COMMENT '',
    dew_point_sensor_id varchar(250) NOT NULL COMMENT '',
    abs_hum_sensor_id varchar(250) NOT NULL COMMENT '',
    temp_sensor_id varchar(250) NOT NULL COMMENT '',
    rel_hum_sensor_id varchar(250) NOT NULL COMMENT '',
    created_on datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '',
    CONSTRAINT `foreign_reference_iot_dew_point_dew_point_sensor_id` FOREIGN KEY(dew_point_sensor_id) REFERENCES iot_sensor(id),
    CONSTRAINT `foreign_reference_iot_dew_point_abs_hum_sensor_id` FOREIGN KEY(abs_hum_sensor_id) REFERENCES iot_sensor(id),
    CONSTRAINT `foreign_reference_iot_dew_point_sensor_temp_sensor_id` FOREIGN KEY(temp_sensor_id) REFERENCES iot_sensor(id),
    CONSTRAINT `foreign_reference_iot_dew_point_sensor_rel_hum_sensor_id` FOREIGN KEY(rel_hum_sensor_id) REFERENCES iot_sensor(id),
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO api_user (id,username,password,is_admin,disabled,solution_id) VALUES (10000,'IoTSrv','password',0,0,10000);
INSERT IGNORE INTO api_user (id,username,password,is_admin,disabled,solution_id) VALUES (10001,'IoTAdmin','password',0,-1,10000);

INSERT IGNORE INTO api_group(id,groupname,solution_id) VALUES (10000,'IoTSensorNetworkSrv',10000);
INSERT IGNORE INTO api_group(id,groupname,solution_id) VALUES (10001,'IoTSensorNetworkAdmin',10000);

INSERT IGNORE INTO api_user_group(user_id,group_id,solution_id) VALUES (10000,10000,10000);
INSERT IGNORE INTO api_user_group(user_id,group_id,solution_id) VALUES (10001,10001,10000);


INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10000,'iot_sensor_data','iot_sensor_data','id','int','sensor_value',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10001,'iot_sensor','iot_sensor','id','int','description',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10002,'iot_sensor_routing','iot_sensor_routing','id','int','description',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10003,'iot_sensor_routing_status','iot_sensor_routing_status','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10004,'iot_log_source','iot_log_source','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10005,'iot_log','iot_log','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10006,'iot_node','iot_node','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10007,'iot_node_status','iot_node_status','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10008,'iot_location','iot_location','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10009,'iot_sensor_type','iot_sensor_type','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10010,'iot_manual_sensor_data','iot_manual_sensor_data','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10011,'iot_manual_sensor_data_status','iot_manual_sensor_data_status','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10012,'iot_device','iot_device','id','string','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10013,'iot_device_class','iot_device_class','id','string','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10014,'iot_device_vendor','iot_device_vendor','id','string','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10015,'iot_device_status','iot_device_status','id','string','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10016,'iot_device_categorie_class_mapping','iot_device_categorie_class_mapping','id','int','category',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10017,'iot_device_routing','iot_device_routing','id','int','description',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10018,'iot_device_attribute','iot_device_attribute','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10019,'iot_device_attribute_value','iot_device_attribute_value','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10020,'iot_sensor_change','iot_sensor_change','id','int','change_text',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10021,'iot_dew_point_sensor','iot_dew_point_sensor','id','int','name',10000);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,solution_id)
    VALUES
    (10022,'iot_device_channel','iot_device_channel','id','int','name',10000);


INSERT IGNORE INTO api_table_field (table_id,label,name,type_id,control_config) VALUES(10017, 'ID','id','int','{"disabled": true}');
INSERT IGNORE INTO api_table_field (table_id,label,name,type_id,control_config) VALUES(10017, 'Erstellt am','created_on','datetime','{"disabled": true}');
INSERT IGNORE INTO api_table_field (table_id,label,name,type_id,control_config) VALUES(10018, 'ID','id','int','{"disabled": true}');
INSERT IGNORE INTO api_table_field (table_id,label,name,type_id,control_config) VALUES(10018, 'Erstellt am','created_on','datetime','{"disabled": true}');
INSERT IGNORE INTO api_table_field (table_id,label,name,type_id,control_config) VALUES(10019, 'Erstellt am','created_on','datetime','{"disabled": true}');
INSERT IGNORE INTO api_table_field (table_id,label,name,type_id,control_config) VALUES(10019, 'ID','id','datetime','{"disabled": true}');

call api_proc_create_table_field_instance(10001,100, 'id','ID','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10001,200, 'alias','Alias','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10001,300, 'description','Bezeichnung','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10001,400, 'last_value','Letzter Wert','decimal',14,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10001,500, 'last_value_on','Letzter Wert von','datetime',9,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10001,600, 'min_value','Min. Wert','decimal',14,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10001,700, 'max_value','Max. Wert','decimal',14,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10001,800, 'unit','Einheit','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10001,900, 'days_in_history','Messwerte aufbewaren (in Tagen)','int',14,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10001,1000, 'auto_delete_sensor_data','Messwerte automatisch löschen','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10001,1100, 'watchdog_warning_sec','Watchdog in Sek.','int',14,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10001,1200, 'type_id','Typ','int',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10001,1300, 'notify','Benachrichtigungen','int',19,'{"disabled": false}', @out_value);

/* iot_device */
call api_proc_create_table_field_instance(10012,100, 'id','ID','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,200, 'name','Bezeichnung','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,300, 'product_id','Product ID (Hersteller)','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,400, 'product_name','Product Name (Hersteller)','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,500, 'address','Adresse','adresse',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,600, 'local_key','Lokaler Key (API)','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,700, 'version','Version','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,700, 'version_available','Verfügbare Version','string',1,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10012,800, 'class_id','Klasse','string',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,900, 'category','Kategorie','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,1000, 'vendor_id','Hersteller','string',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,1100, 'status_id','Status','string',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,1200, 'location_id','Standort','int',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,1300, 'icon','Icon','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10012,1400, 'created_on','Erstellt am','datetime',9,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10012,1500, 'last_scan_on','Letzter Scan','datetime',9,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10012,1600, 'network_ssid','Netzwerk SSID','string',1,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10012,1700, 'network_rssi','RSSI (Netzwerk)','int',14,'{"disabled": true}', @out_value);

/* iot_device_channel */
call api_proc_create_table_field_instance(10022,100, 'id','ID','int',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10022,200, 'name','Bezeichnung','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10022,300, 'alias','Alias','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10022,400, 'device_id','Device','string',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10022,500, 'channel','Kanal','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10022,600, 'Channel_value','Letzter Wert','string',1,'{"disabled": false}', @out_value);



/* iot_device_routing */
call api_proc_create_table_field_instance(10017,100, 'id','ID','int',14,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10017,200, 'internal_device_id','Interne ID','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10017,300, 'external_device_id','Externe ID','string',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10017,400, 'description','Bezeichnung im Dashboard','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10017,500, 'show_dashboard','Anzeige im Dashboard','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10017,600, 'dashboard_pos','Dashboard Pos','int',14,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10017,700, 'created_on','Erstellt am','datetime',9,'{"disabled": true}', @out_value);

/* localtion */
call api_proc_create_table_field_instance(10008,100, 'id','ID','int',14,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10008,100, 'name','Name','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10008,100, 'local_gateway_url','Gateway URL (HTTP)','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10008,100, 'local_gateway_topic','Gateway Topic (MQTT)','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10008,100, 'local_gateway_protocol','Gateway Protokoll','string',20,'{"disabled": false}', @out_value);
UPDATE api_table_field SET control_config='{"listitems": "mqtt;MQTT|http;HTTP"}' WHERE id=@out_value;

/* iot_node */
call api_proc_create_table_field_instance(10006,100, 'id','ID','int',14,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10006,200, 'name','Name','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,300, 'last_error_code','Letzter Fehlercode','int',14,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10006,400, 'ip_address','IP Adresse','string',1,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10006,500, 'last_heard_on','Zuletzt gehört','datetime',9,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10006,600, 'status_id','Status','int',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,700, 'location_id','Ort','int',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,800, 'display_template','Display (jinja)','string',18,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,900, 'version','Version','string',1,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10006,1000, 'define_onewire','#define onewire','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,1100, 'define_dht','#define dht','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,1200, 'define_dht_type','#define dht_type','string',20,'{"listitems": "DHT11;DHT11|DHT22;DHT22", "disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,1300, 'define_lightness','#define lightness','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,1400, 'define_rainfall','#define rainfall','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,1500, 'define_display','#define display','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,1600, 'define_mqtt','#define mqtt','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,1700, 'define_http','#define http','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,1800, 'define_https','#define https','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,1900, 'define_ota','#define ota','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,2000, 'define_bmp','#define bmp','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,2100, 'define_espnow_sub','#define espnow_sub','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,2200, 'define_espnow_pub','#define espnow_pub','int',19,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10006,2300, 'define_mlx90614','#define mlx90614','int',19,'{"disabled": false}', @out_value);

/* sensor change */
call api_proc_create_table_field_instance(10020,100, 'id','ID','int',14,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10020,100, 'change_subject','Subject','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10020,100, 'sensor_id','Sensor','string',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10020,100, 'change_date','Datum','datetime',9,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10020,100, 'change_text','Text','string',18,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10020,100, 'created_on','Erstellt am','datetime',9,'{"disabled": true}', @out_value);

/* dew_point_sensor */
DELETE FROM api_table_field WHERE table_id=10021;
call api_proc_create_table_field_instance(10021,100, 'id','ID','int',14,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10021,200, 'name','Bezeichnung','int',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10021,300, 'temp_sensor_id','Temperatur Sensor (Eingang)','int',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10021,400, 'rel_hum_sensor_id','Rel. Luftfeuchte Sensor (Eingang)','int',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10021,500, 'dew_point_sensor_id','Taupunkt Sensor (Ausgang)','int',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10021,500, 'abs_hum_sensor_id','Abs. Luftfeuchte Sensor (Ausgang)','int',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10021,800, 'created_on','Erstellt am','datetime',9,'{"disabled": true}', @out_value);

/* device_channel */
call api_proc_create_table_field_instance(10022,100, 'id','ID','int',14,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(10022,200, 'name','Bezeichnung','int',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10022,300, 'device_id','Device','string',2,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10022,400, 'channel','Kanal (Device)','string',1,'{"disabled": false}', @out_value);
call api_proc_create_table_field_instance(10022,500, 'channel_value','Last value','string',1,'{"disabled": false}', @out_value);


INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10000,-1,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10001,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10002,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10003,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10004,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10005,-1,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10006,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10007,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10008,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10009,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10010,-1,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10011,0,-1,0,10000);

INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10012,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10013,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10014,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10015,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10016,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10018,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10018,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10019,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10020,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10021,0,-1,0,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,solution_id)
    VALUES
    (10000,10022,0,-1,0,10000);



/* Admin */
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10000,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10001,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10002,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10003,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10004,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10005,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10006,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10007,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10008,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10009,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10010,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10011,-1,-1,-1,-1,10000);

INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10012,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10013,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10014,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10015,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10016,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10017,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10018,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10019,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10020,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10021,-1,-1,-1,-1,10000);
INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (10001,10022,-1,-1,-1,-1,10000);



INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,solution_id) 
    VALUES (10000001,'iot_sensor_routing','iot_sensor_data','insert','before',90,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,solution_id)
    VALUES (10000002,'iot_setlast_value','iot_sensor_data','insert','before',100,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,solution_id)
    VALUES (10000003,'iot_set_node_status','iot_log','insert','before',100,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,solution_id)
    VALUES (10000004,'iot_action_display','iot_get_node_display_text','execute','before',100,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,solution_id)
    VALUES (10000005,'iot_app_start','$app_start','execute','before',100,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,run_async,solution_id)
    VALUES (10000006,'iot_pl_man_sensor_data','iot_manual_sensor_data','insert','after',100,-1,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,run_async,solution_id)
    VALUES (10000007,'iot_action_gw','iot_action_gw','execute','before',100,0,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,run_async,solution_id)
    VALUES (10000008,'iot_action_shelly_mqtt','iot_action_shelly_mqtt','execute','before',100,0,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,run_async,solution_id)
    VALUES (10000009,'iot_plugin_shelly_sub_switsh_set','iot_shelly','mqtt_message','after',100,0,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,run_async,solution_id)
    VALUES (10000010,'iot_action_device_switch','iot_action_device_switch','execute','before',100,0,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,run_async,solution_id)
    VALUES (10000011,'iot_plugin_add_portal_params','iot_demo','render_portal_content','before',100,0,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,solution_id)
    VALUES (10000012,'iot_action_set_last_heard','iot_action_set_last_heard','execute','before',100,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,run_async,solution_id)
    VALUES (10000013,'iot_plugin_dk9mbs_sub_switsh_set','iot_dk9mbs_device_status','mqtt_message','after',100,0,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,run_async,solution_id)
    VALUES (10000014,'iot_plugin_set_last_heard','iot_sys_pong','mqtt_message','after',100,0,10000);

INSERT IGNORE INTO api_event_handler(id,plugin_module_name,publisher,event,type,run_async,config,solution_id) 
    VALUES (
        10000015,'api_mqtt_endpoint','iot_sensor_data','insert','after',-1,
        '{"endpoint":"restapi/$instance/solution/iot/event/$publisher/$trigger/$value_sensor_id", "filter": "[\'sensor_id\', \'sensor_value\']"}',
        10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,run_async,solution_id)
    VALUES (10000016,'iot_action_dew_point','iot_action_dew_point','execute','before',100,0,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,solution_id)
    VALUES (10000017,'iot_plugin_calc_dew_point','iot_sensor_data','insert','before',100,10000);

INSERT IGNORE INTO api_event_handler(id,plugin_module_name,publisher,event,type,run_async,solution_id) 
    VALUES (10000018,'iot_plugin_sensor_watchdog','$timer_every_minute','execute','after',0,10000);

INSERT IGNORE INTO api_event_handler (id,plugin_module_name,publisher,event,type,sorting,run_async,solution_id)
    VALUES (10000019,'iot_plugin_shelly_notify_status','iot_shelly_events','mqtt_message','after',100,0,10000);





INSERT IGNORE INTO api_ui_app (id, name,description,home_url,solution_id)
VALUES (
10000,'IoT Service App','System Verwaltungs App','/ui/v1.0/data/view/iot_sensor/default?app_id=10000',10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10000,10000,'Sensoren','/ui/v1.0/data/view/iot_sensor/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10001,10000,'Sensor Daten (avg)','/ui/v1.0/data/view/iot_sensor_data/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10002,10000,'Nodes','/ui/v1.0/data/view/iot_node/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10003,10000,'Logs','/ui/v1.0/data/view/iot_log/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10004,10000,'Routing','/ui/v1.0/data/view/iot_sensor_routing/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10005,10000,'Locations','/ui/v1.0/data/view/iot_location/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10006,10000,'Sensor Typen','/ui/v1.0/data/view/iot_sensor_type/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10007,10000,'Zählerstandserfassung','/ui/v1.0/data/view/iot_manual_sensor_data/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10008,10000,'Status werte Zählerstandserfassung','/ui/v1.0/data/view/iot_manual_sensor_data_status/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10009,10000,'Aktoren','/ui/v1.0/data/view/iot_device/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10010,10000,'Kategorien Mapping','/ui/v1.0/data/view/iot_device_categorie_class_mapping/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10011,10000,'Device Routing','/ui/v1.0/data/view/iot_device_routing/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10012,10000,'Sensor Changes','/ui/v1.0/data/view/iot_sensor_change/default',1,10000);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
10013,10000,'Taupunkt Sensoren','/ui/v1.0/data/view/iot_dew_point_sensor/default',1,10000);


INSERT IGNORE INTO api_mqtt_message_bus (id, topic, regex, alias, solution_id) VALUES (100000001, '+/rpc', '^shelly.*/rpc$', 'iot_shelly/',10000);
UPDATE api_mqtt_message_bus SET regex='^shelly.*-[0-9a-z]{12,}\/rpc$' WHERE id=100000001 AND regex='^shelly.*/rpc$';

INSERT IGNORE INTO api_mqtt_message_bus (id, topic, regex, alias, solution_id) VALUES (100000002, 'restapi/solution/iot/sys/node/pong', '^restapi/solution/iot/sys/node/pong$', 'iot_sys_pong/',10000);
INSERT IGNORE INTO api_mqtt_message_bus (id, topic, regex, alias, solution_id) VALUES (100000003, 'restapi/solution/iot/dk9mbs/status/rpc', '^restapi/solution/iot/dk9mbs/status/rpc$', 'iot_dk9mbs_device_status/',10000);
INSERT IGNORE INTO api_mqtt_message_bus (id, topic, regex, alias, solution_id) VALUES (100000004, '+/events/rpc', '^shelly.*/events/rpc$', 'iot_shelly_events/',10000);



/* Listviews */
INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10001,'LISTVIEW','default',10001,'id',10000,'<restapi type="select">
    <table name="iot_sensor" alias="s"/>
    <filter type="or">
        <condition field="description" table_alias="s" value="$$query$$" operator=" like "/>
        <condition field="alias" table_alias="s" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="last_value_on" alias="s" sort="DESC"/>
    </orderby>
    <joins>
        <join type="left" table="iot_sensor_type" alias="st" condition="s.type_id=st.id"/>
    </joins>
    <select>
        <field name="id" table_alias="s" alias="id" header="ID"/>
        <field name="name" table_alias="st" header="Type"/>
        <field name="description" table_alias="s" header="Description"/>
        <field name="last_value" table_alias="s" header="Value (current)"/>
        <field name="unit" table_alias="s" header="Unit"/>
        <field name="last_value_on" table_alias="s" header="Last value on"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10002,'SELECTVIEW','default',10001,'id',10000,'<restapi type="select">
    <table name="iot_sensor" alias="s"/>
    <orderby>
        <field name="description" alias="s" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="s" alias="id"/>
        <field name="description" table_alias="s" alias="name"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10003,'LISTVIEW','default',10002,'id',10000,'<restapi type="select">
    <table name="iot_sensor_routing" alias="r"/>
    <filter type="or">
        <condition field="description" alias="r" value="$$query$$" operator=" like "/>
        <condition field="external_sensor_id" alias="r" value="$$query$$" operator=" like "/>
        <condition field="internal_sensor_id" alias="r" value="$$query$$" operator=" like "/>
    </filter>
    <joins>
        <join type="inner" table="iot_sensor_routing_status" alias="rs" condition="r.status_id=rs.id"/>
        <join type="left" table="iot_sensor" alias="s" condition="r.internal_sensor_id=s.id"/>
    </joins>
    <orderby>
        <field name="external_sensor_id" alias="r" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="r" alias="id"/>
        <field name="external_sensor_id" table_alias="r"/>
        <field name="internal_sensor_id" table_alias="r"/>
        <field name="description" table_alias="r" alias="Routing"/>
        <field name="description" table_alias="s" alias="Sensor"/>
        <field name="name" table_alias="rs" alias="status"/>
        <field name="last_value_on" table_alias="r"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10005,'LISTVIEW','default',10003,'id',10000,'<restapi type="select">
    <table name="iot_sensor_routing_status" alias="rs"/>
    <filter type="or">
        <condition field="name" alias="rs" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="id" alias="rs" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="rs" alias="id"/>
        <field name="name" table_alias="rs"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10006,'SELECTVIEW','default',10003,'id',10000,'<restapi type="select">
    <table name="iot_sensor_routing_status" alias="rs"/>
    <filter type="or">
        <condition field="name" alias="rs" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="id" alias="rs" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="rs" alias="id"/>
        <field name="name" table_alias="rs" alias="name"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10007,'LISTVIEW','default',10004,'id',10000,'<restapi type="select">
    <table name="iot_log_source" alias="l"/>
    <filter type="or">
        <condition field="name" alias="l" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="name" alias="l" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="l" alias="id"/>
        <field name="name" table_alias="l"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10008,'SELECTVIEW','default',10004,'id',10000,'<restapi type="select">
    <table name="iot_log_source" alias="l"/>
    <filter type="or">
        <condition field="name" alias="l" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="name" alias="l" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="l" alias="id"/>
        <field name="name" table_alias="l" alias="name"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10009,'LISTVIEW','default',10005,'id',10000,'<restapi type="select">
    <table name="iot_log" alias="l"/>
    <filter type="or">
        <condition field="name" alias="l" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="id" alias="l" sort="DESC"/>
    </orderby>
    <select>
        <field name="id" table_alias="l" alias="id"/>
        <field name="name" table_alias="l"/>
        <field name="message" table_alias="l"/>
        <field name="node_id" table_alias="l"/>
        <field name="node_name" table_alias="l"/>
        <field name="ip_address" table_alias="l"/>
        <field name="created_on" table_alias="l"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10011,'LISTVIEW','default',10006,'id',10000,'<restapi type="select">
    <table name="iot_node" alias="n"/>
    <filter type="or">
        <condition field="name" alias="n" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="name" alias="n" sort="ASC"/>
    </orderby>
    <joins>
        <join type="inner" table="iot_node_status" alias="ns" condition="n.status_id=ns.id"/>
        <join type="left" table="iot_location" alias="l" condition="n.location_id=l.id"/>
    </joins>
    <select>
        <field name="id" table_alias="n" alias="id" header="ID"/>
        <field name="name" table_alias="n" alias="test" header="Node Name"/>
        <field name="ip_address" table_alias="n" header="IP"/>
        <field name="last_heard_on" table_alias="n" header="Last heard"/>
        <field name="last_error_code" table_alias="n" header="Last Error"/>
        <field name="version" table_alias="n" header="Version"/>
        <field name="name" table_alias="ns" header="Status"/>
        <field name="name" table_alias="l" alias="location_name" header="Location"/>
        <field name="status_id" table_alias="n" header="StatusID"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10012,'SELECTVIEW','default',10006,'id',10000,'<restapi type="select">
    <table name="iot_node" alias="n"/>
    <orderby>
        <field name="name" alias="n" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="n" alias="id"/>
        <field name="name" table_alias="n"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10013,'LISTVIEW','default',10007,'id',10000,'<restapi type="select">
    <table name="iot_node_status" alias="n"/>
    <orderby>
        <field name="name" alias="n" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="n" alias="id"/>
        <field name="name" table_alias="n" alias="name"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10014,'SELECTVIEW','default',10007,'id',10000,'<restapi type="select">
    <table name="iot_node_status" alias="n"/>
    <orderby>
        <field name="name" alias="n" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="n" alias="id"/>
        <field name="name" table_alias="n" alias="name"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10015,'LISTVIEW','default',10008,'id',10000,'<restapi type="select">
    <table name="iot_location" alias="l"/>
    <filter type="or">
        <condition field="name" alias="l" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="name" alias="l" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="l" alias="id" header="ID"/>
        <field name="name" table_alias="l" alias="test" header="Location"/>
        <field name="local_gateway_protocol" table_alias="l" header="Protokoll"/>

    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10016,'SELECTVIEW','default',10008,'id',10000,'<restapi type="select">
    <table name="iot_location" alias="l"/>
    <filter type="or">
        <condition field="name" alias="l" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="name" alias="l" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="l" alias="id"/>
        <field name="name" table_alias="l" alias="name"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10017,'LISTVIEW','default',10009,'id',10000,'<restapi type="select">
    <table name="iot_sensor_type" alias="t"/>
    <filter type="or">
        <condition field="name" alias="t" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="name" alias="t" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="t" alias="id" header="ID"/>
        <field name="name" table_alias="t" alias="test" header="Name"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10018,'SELECTVIEW','default',10009,'id',10000,'<restapi type="select">
    <table name="iot_sensor_type" alias="t"/>
    <orderby>
        <field name="name" alias="t" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="t" alias="id"/>
        <field name="name" table_alias="t" alias="name"/>
    </select>
</restapi>');

/* avg over sensor */
INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10019,'LISTVIEW','default',10000,'id',10000,'<restapi type="select">
    <table name="iot_sensor_data" alias="sd"/>
    <filter type="and">
        <condition field="sensor_value" alias="sd" operator="notnull"/>
        <condition field="id" alias="s" operator="notnull"/>
        <filter type="and">
            <condition field="sensor_id" alias="sd" value="$$query$$" operator=" like "/>
        </filter>
    </filter>
    <joins>
        <join type="left" table="iot_sensor" alias="s" condition="sd.sensor_id=s.id"/>
    </joins>
    <select>
        <field name="id" table_alias="s" alias="id" grouping="y" header="ID"/>
        <field name="description" table_alias="s" grouping="y" header="Description"/>
        <field name="sensor_value" table_alias="sd" func="avg" alias="last_value" header="Value (avg)"/>
        <field name="unit" table_alias="s" grouping="y" header="Unit"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10020,'LISTVIEW','default',10010,'id',10000,'<restapi type="select">
    <table name="iot_manual_sensor_data" alias="m"/>
    <filter type="or">
        <condition field="name" alias="m" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <joins>
        <join type="inner" table="iot_manual_sensor_data_status" alias="s" condition="s.id=m.status_id"/>
    </joins>
    <orderby>
        <field name="created_on" alias="m" sort="DESC"/>
    </orderby>
    <select>
        <field name="id" table_alias="m" alias="id" header="ID"/>
        <field name="name" table_alias="m" header="Name"/>
        <field name="external_sensor_id" table_alias="m" header="Zähler"/>
        <field name="value" table_alias="m" header="Wert"/>
        <field name="name" alias="status_name" table_alias="s" header="Status"/>
        <field name="error_text" table_alias="m" header="Fehler"/>
        <field name="created_on" table_alias="m" header="Datum"/>
    </select>
</restapi>');


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10021,'LISTVIEW','default',10012,'id',10000,'<restapi type="select">
    <table name="iot_device" alias="d"/>
    <filter type="or">
        <condition field="name" alias="d" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <joins>
        <join type="inner" table="iot_device_status" alias="s" condition="s.id=d.status_id"/>
    </joins>
    <orderby>
        <field name="created_on" alias="d" sort="DESC"/>
    </orderby>
    <select>
        <field name="id" table_alias="d" alias="id" header="ID"/>
        <field name="name" table_alias="d" header="Name"/>
        <field name="address" table_alias="d" header="Adresse"/>
        <field name="name" alias="status_name" table_alias="s" header="Status"/>
        <field name="class_id" table_alias="d" header="Geräte Klasse"/>
        <field name="last_scan_on" table_alias="d" header="Letzter Netzwerk Scan"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10022,'LISTVIEW','default',10016,'id',10000,'<restapi type="select">
    <table name="iot_device_categorie_class_mapping" alias="m"/>
    <filter type="or">
        <condition field="category" alias="m" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <orderby>
        <field name="category" alias="m" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="m" alias="id" header="ID"/>
        <field name="category" table_alias="m" header="Kategorie"/>
        <field name="class_id" table_alias="m" header="Klasse"/>
        <field name="vendor_id" table_alias="m" header="Hersteller"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10023,'LISTVIEW','default',10017,'id',10000,'<restapi type="select">
    <table name="iot_device_routing" alias="r"/>
    <filter type="or">
        <condition field="internal_device_id" alias="r" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <orderby>
        <field name="internal_device_id" alias="r" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="r" alias="id" header="ID"/>
        <field name="internal_device_id" table_alias="r" header="Intern"/>
        <field name="external_device_id" table_alias="r" header="Extern"/>
        <field name="description" table_alias="r" header="Bemerkung"/>
        <field name="created_on" table_alias="r" header="Erstellt am"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10024,'LISTVIEW','default',10020,'id',10000,'<restapi type="select">
    <table name="iot_sensor_change" alias="r"/>
    <filter type="or">
        <condition field="sensor_id" alias="r" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <orderby>
        <field name="change_date" alias="r" sort="ASC"/>
    </orderby>
    <select>
        <field name="id" table_alias="r" alias="id" header="ID"/>
        <field name="sensor_id" table_alias="r" header="Sensor"/>
        <field name="change_subject" table_alias="r" header="Subject"/>
        <field name="change_date" table_alias="r" header="Datum"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
10025,'LISTVIEW','default',10000,'id',10000,'<restapi type="select">
    <table name="iot_sensor_data" alias="s"/>
    <filter type="or">
        <condition field="sensor_namespace" table_alias="s" value="$$query$$" operator=" like "/>
    </filter>
    <orderby>
        <field name="id" alias="s" sort="DESC"/>
    </orderby>
    <select>
        <field name="id" table_alias="s" alias="id" header="ID"/>
        <field name="sensor_id" table_alias="st" header="Type"/>
        <field name="sensor_namespace" table_alias="s" header="Description"/>
        <field name="sensor_value" table_alias="s" header="Value (current)"/>
        <field name="created_on" table_alias="s" header="Unit"/>
    </select>
</restapi>');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml, columns) VALUES (
10026,'LISTVIEW','default',10021,'id',10000,'<restapi type="select">
    <table name="iot_dew_point_sensor" alias="r"/>
    <filter type="or">
        <condition field="temp_sensor_id" alias="r" value="$$query$$" operator="$$operator$$"/>
        <condition field="name" alias="r" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <orderby>
        <field name="id" alias="r" sort="ASC"/>
    </orderby>
</restapi>', '{"id": {},"name": {}}');

INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml, columns) VALUES (
10027,'LISTVIEW','default',10022,'id',10000,'<restapi type="select">
    <table name="iot_device_channel" alias="r"/>
    <filter type="or">
        <condition field="name" alias="r" value="$$query$$" operator="$$operator$$"/>
        <condition field="device_id" alias="r" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <orderby>
        <field name="id" alias="r" sort="ASC"/>
    </orderby>
</restapi>', '{"id": {},"device_id":{},"alias":{},"name": {},"channel":{}, "channel_value":{} }');