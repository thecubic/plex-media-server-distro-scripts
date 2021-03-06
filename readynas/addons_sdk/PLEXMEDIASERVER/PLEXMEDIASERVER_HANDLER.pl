#!/usr/bin/perl
#-------------------------------------------------------------------------
#  Copyright 2007, NETGEAR
#  All rights reserved.
#-------------------------------------------------------------------------

do "/frontview/lib/cgi-lib.pl";
do "/frontview/lib/addon.pl";

# initialize the %in hash
%in = ();
ReadParse();

my $operation      = $in{OPERATION};
my $command        = $in{command};
my $enabled        = $in{"CHECKBOX_PLEXMEDIASERVER_ENABLED"};
my $data           = $in{"data"};

get_default_language_strings("PLEXMEDIASERVER");
 
my $xml_payload = "Content-type: text/xml; charset=utf-8\n\n"."<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
 
if( $operation eq "get" )
{
  $xml_payload .= Show_PLEXMEDIASERVER_xml();
}
elsif( $operation eq "set" )
{
  if( $command eq "RemoveAddOn" )
  {
    # Remove_Service_xml() removes this add-on
    $xml_payload .= Remove_Service_xml("PLEXMEDIASERVER", $data);
  }
  elsif ($command eq "ToggleService")
  {
    # Toggle_Service_xml() toggles the enabled state of the add-on
    $xml_payload .= Toggle_Service_xml("PLEXMEDIASERVER", $enabled);
  }
  elsif ($command eq "ModifyAddOnService")
  {
    # Modify_PLEXMEDIASERVER_xml() processes the input form changes
    $xml_payload .= Modify_PLEXMEDIASERVER_xml();
  }
}

print $xml_payload;
  

sub Show_PLEXMEDIASERVER_xml
{
  my $xml_payload = "<payload><content>" ;

  # check if service is running or not 
  my $enabled = GetServiceStatus("PLEXMEDIASERVER");

  # get PLEXMEDIASERVER_RUNTIME_SECS parameter from /etc/default_services
  my $run_time = GetValueFromServiceFile("PLEXMEDIASERVER_RUNTIME_SECS");

  if( $run_time eq "not_found" )
  {
    # set run_time to a default value
    $run_time = "60";
  }

  my $enabled_disabled = "disabled";
     $enabled_disabled = "enabled" if( $enabled );

  # return run_time value for HTML
  $xml_payload .= "<PLEXMEDIASERVER_RUNTIME_SECS><value>$run_time</value><enable>$enabled_disabled</enable></PLEXMEDIASERVER_RUNTIME_SECS>"; 

  $xml_payload .= "</content><warning>No Warnings</warning><error>No Errors</error></payload>";
  
  return $xml_payload;
}


sub Modify_PLEXMEDIASERVER_xml 
{
  my $run_time  = $in{"PLEXMEDIASERVER_RUNTIME_SECS"};
  my $SPOOL;
  my $xml_payload;
  
  $run_time = "60" if( $run_time eq "" );
  
  $SPOOL .= "
if grep -q PLEXMEDIASERVER_RUNTIME_SECS /etc/default/services; then
  sed -i 's/PLEXMEDIASERVER_RUNTIME_SECS=.*/PLEXMEDIASERVER_RUNTIME_SECS=${run_time}/' /etc/default/services
else
  echo 'PLEXMEDIASERVER_RUNTIME_SECS=${run_time}' >> /etc/default/services
fi
";
 
  if( $in{SWITCH} eq "YES" ) 
  {
    $xml_payload = Toggle_Service_xml("PLEXMEDIASERVER", $enabled);
  }
  else
  {
    spool_file("${ORDER_SERVICE}_PLEXMEDIASERVER", $SPOOL);
    empty_spool();

    $xml_payload = _build_xml_set_payload_sync();
  }
  return $xml_payload;
}


1;
