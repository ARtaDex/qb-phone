-- Hapus tabel lama jika ada untuk menghindari konflik (Opsional, hati-hati jika ada data penting)
-- DROP TABLE IF EXISTS `player_contacts`;
-- DROP TABLE IF EXISTS `phone_invoices`;
-- DROP TABLE IF EXISTS `phone_messages`;
-- DROP TABLE IF EXISTS `player_mails`;
-- DROP TABLE IF EXISTS `crypto_transactions`;
-- DROP TABLE IF EXISTS `phone_gallery`;
-- DROP TABLE IF EXISTS `phone_tweets`;

-- 1. Kontak Pemain
CREATE TABLE IF NOT EXISTS `player_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) DEFAULT NULL, -- Diganti dari citizenid
  `name` varchar(50) DEFAULT NULL,
  `number` varchar(50) DEFAULT NULL,
  `iban` varchar(50) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Tagihan / Invoice (Billing)
CREATE TABLE IF NOT EXISTS `phone_invoices` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) DEFAULT NULL, -- Diganti dari citizenid
  `amount` int(11) NOT NULL DEFAULT 0,
  `society` tinytext DEFAULT NULL,
  `sender` varchar(50) DEFAULT NULL,
  `sendercitizenid` varchar(60) DEFAULT NULL, -- Diganti (menyimpan identifier pengirim)
  `candecline` int(1) NOT NULL DEFAULT 1,
  `reason` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Pesan SMS
CREATE TABLE IF NOT EXISTS `phone_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) DEFAULT NULL, -- Diganti dari citizenid
  `number` varchar(50) DEFAULT NULL,
  `messages` longtext DEFAULT NULL, -- Menggunakan longtext agar muat banyak chat
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `number` (`number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Email
CREATE TABLE IF NOT EXISTS `player_mails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) DEFAULT NULL, -- Diganti dari citizenid
  `sender` varchar(50) DEFAULT NULL,
  `subject` varchar(50) DEFAULT NULL,
  `message` longtext DEFAULT NULL,
  `read` tinyint(4) DEFAULT 0,
  `mailid` int(11) DEFAULT NULL,
  `date` timestamp NULL DEFAULT current_timestamp(),
  `button` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Transaksi Kripto
CREATE TABLE IF NOT EXISTS `crypto_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) DEFAULT NULL, -- Diganti dari citizenid
  `title` varchar(50) DEFAULT NULL,
  `message` varchar(50) DEFAULT NULL,
  `date` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Galeri Foto
CREATE TABLE IF NOT EXISTS `phone_gallery` (
   `identifier` VARCHAR(60) NOT NULL, -- Diganti dari citizenid
   `image` VARCHAR(255) NOT NULL,
   `date` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Twitter / Tweets
CREATE TABLE IF NOT EXISTS `phone_tweets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(60) DEFAULT NULL, -- Tetap dinamakan citizenid agar kompatibel dengan JS, tapi isinya identifier ESX
  `firstName` varchar(25) DEFAULT NULL,
  `lastName` varchar(25) DEFAULT NULL,
  `message` longtext DEFAULT NULL,
  `date` datetime DEFAULT current_timestamp(),
  `url` text DEFAULT NULL,
  `picture` text DEFAULT './img/default.png',
  `tweetId` varchar(25) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- CATATAN PENTING:
-- Tabel `player_vehicles` TIDAK disertakan di sini.
-- ESX menggunakan tabel `owned_vehicles` secara bawaan.
-- Script server.lua yang saya berikan sebelumnya sudah disesuaikan untuk membaca `owned_vehicles`.