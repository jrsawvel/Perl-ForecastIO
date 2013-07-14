#!/usr/bin/perl -wT
use strict;
$|++;
BEGIN {
    unshift @INC, "../lib";
}

use ForecastIO;

print "Executing program: $0\n\n";

my $api_key = "<api key>";
my $latitude = "41.665556";
my $longitude = "-83.575278";

my $forecast = ForecastIO->new($api_key, $latitude, $longitude);


# change url for testing
# $forecast->api_url("http://testurl/jsoncopy.txt");

# get old data
# $forecast->api_url( $forecast->api_url . ",2012-07-11T12:00:00-0400" );

# download json data and convert to perl hash
$forecast->fetch_data;

# or don't change api_url and use different fetch command with date and time arg
# $forecast->fetch_data_for_date("2012-07-11T12:00:00-0400");

my $currently = $forecast->currently;
print $currently->temperature . "\n";

my @alerts = $forecast->alerts;
if ( @alerts ) {
    foreach my $a ( @alerts ) {
        print "  alert =   " . $a->alert_title  . "\n";
        print "  uri =     " . $a->alert_uri . "\n";
        print "  expires = " . $a->alert_expires . "\n\n";
        print "   fmt dt = " . ForecastIOUtils::format_date($a->alert_expires) . "\n\n";
    }
} else {
    print "\n all clear. no alerts.\n"; 
}

my @hourly = $forecast->hourly;
if ( @hourly ) {
foreach my $h ( @hourly ) {
    print ForecastIOUtils::format_date( $h->time ) .  
    " : test =  " . $h->sunsetTime .  
    " : icon =  " . $h->icon .  
    " : temp = "  . ForecastIOUtils::round($h->temperature) . 
    " : precip intenity =  " . $h->precipIntensity .  
    " : pressure = " . ForecastIOUtils::millibars_to_inches($h->pressure) . " in. " .
    " : wind direction = " . ForecastIOUtils::degrees_to_cardinal($h->windBearing) .  
#    " : wind speed = " . $h->windSpeed . " mph " .  
    " : wind speed = " . ForecastIOUtils::round($h->windSpeed) . " mph " .  
    "\n";
}
}

my @minutely = $forecast->minutely;
if ( @minutely ) {
foreach my $m ( @minutely ) {
    print ForecastIOUtils::format_date( $m->time ) . " : " . $m->precipIntensity . "\n";
}
}

my @daily = $forecast->daily;
if ( @daily ) {
foreach my $d ( @daily ) {
    print ForecastIOUtils::format_date( $d->time ) . " : " . $d->icon . "\n";
}
}

print "\n\n offset = " . $forecast->offset . "\n";
print "\n timezone = " . $forecast->timezone . "\n";
print "\n hourly summary = " . $forecast->hourlysummary . "\n";
print "\n daily summary = " . $forecast->dailysummary . "\n";
print "\n minutely summary = " . $forecast->minutelysummary . "\n";

print "\n Current date time in default format: " . ForecastIOUtils::format_date() . "\n";
print "\n Current date time format arg: " . ForecastIOUtils::format_date(0, "(12hr):(0min) (a.p.) - (dayfullname), (monthfullname) (daynum), (yearfull)") . "\n";   # have to provide zero for epoch to use current time
    
