CREATE TABLE IF NOT EXISTS `meetme_users` (
  `citizenid` varchar(50) NOT NULL,
  `known_people` longtext NOT NULL,
  `settings` longtext NOT NULL,
  PRIMARY KEY (`citizenid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;