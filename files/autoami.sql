--
-- Table structure for table `nodes`
--

DROP TABLE IF EXISTS `nodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nodes` (
  `dns_name` varchar(255) NOT NULL,
  `ami_group` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nodes`
--

DROP TABLE IF EXISTS `groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `groups` (
  `name` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `image` varchar(255) NOT NULL,
  `keyname` varchar(255) NOT NULL,
  `keyfile` varchar(255) NOT NULL,
  `login` varchar(255) NOT NULL,
  `server` varchar(255) NOT NULL,
  `enc_server` varchar(255) NOT NULL,
  `enc_user` varchar(255) NOT NULL,
  `enc_pass` varchar(255) NOT NULL,
  `enc_port` varchar(255) NOT NULL,
  `node_group` varchar(255) NOT NULL,
  `region` varchar(255) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
