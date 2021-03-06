#!/usr/bin/perl -wT
use strict;
$|++;
BEGIN {
    unshift @INC, "../lib";
}

use ForecastIO;

# Details on what's available in the Forecast.io API can be found at:
# https://developer.forecast.io/docs/v2

print "Executing program: $0\n\n";

#### my $api_key = "<api key>";
my $api_key = "<api key>";
# Toledo, Ohio
my $latitude = "41.665556";
my $longitude = "-83.575278";

my $forecast = ForecastIO->new($api_key, $latitude, $longitude);

# change url for testing with a downloaded, saved copy of JSON data
# $forecast->api_url("http://testurl/saveddata.json");
# print "Testing with saved Toledo, OH data set for July 10, 2013\n\n";

# get old data
# $forecast->api_url( $forecast->api_url . ",2012-07-11T12:00:00-0400" );

# download json data and convert to perl hash
$forecast->fetch_data;

# or don't change api_url and use different fetch command with date and time arg
# $forecast->fetch_data_for_date("2012-07-11T12:00:00-0400");


print "Current Weather Conditions\n";
my $currently      = $forecast->currently;
my $wind_direction = ForecastIOUtils::degrees_to_cardinal($currently->windBearing);
my $wind_speed     = ForecastIOUtils::round($currently->windSpeed);
$wind_speed        = 0 if $wind_speed eq "undef";
$wind_direction    = "Calm wind" if $wind_speed == 0; 

print "         date and time = " . ForecastIOUtils::format_date($currently->time) . "\n"; 
print "               summary = " . $currently->summary . "\n";
print "                  icon = " . $currently->icon . "\n";
print "              air temp = " . ForecastIOUtils::round($currently->temperature) . "\n";
print "             dew point = " . ForecastIOUtils::round($currently->dewPoint) . "\n";
print "         wind directon = " . $wind_direction . "\n";
print "            wind speed = " . $wind_speed . " mph\n";
print "              pressure = " . ForecastIOUtils::millibars_to_inches($currently->pressure) . " in. " . "\n";
print "              humidity = " . $currently->humidity * 100 . "% \n";
print "                 ozone = " . $currently->ozone . " Dobson units\n";
print "           precip prob = " . $currently->precipProbability * 100 . "% \n";
print "           cloud cover = " . $currently->cloudCover * 100 . "%\n";
print "      cloud cover desc = " . ForecastIOUtils::cloud_cover_description($currently->cloudCover) . "\n";
print "      precip intensity = " . $currently->precipIntensity . "\n";
print " precip intensity desc = " . ForecastIOUtils::calc_intensity($currently->precipIntensity) . "\n";
print "precip intensity color = " . ForecastIOUtils::calc_intensity_color($currently->precipIntensity) . "\n";
print "           precip type = " . $currently->precipType . "\n";
print "            visibility = " . $currently->visibility . " miles\n";


# forecast.io added the description data for an alert on July 17, 2013
print "\nCurrent Alerts\n";

my @alerts = $forecast->alerts;
if ( @alerts ) {
    foreach my $a ( @alerts ) {
        print "alert =       " . $a->alert_title  . "\n";
        print "uri =         " . $a->alert_uri . "\n";
        print "expires =     " . ForecastIOUtils::format_date($a->alert_expires) . "\n";
        print "description = " . $a->alert_description . "\n";
    }
} else {
    print "\n all clear. no alerts.\n"; 
}


print "\nHourly Forecast - Next 48 Hours\n";

my @hourly = $forecast->hourly;
if ( @hourly ) {
    foreach my $h ( @hourly ) {
        print ForecastIOUtils::format_date( $h->time ) .  
        " : icon =  "             . $h->icon .  
        " : temp = "              . ForecastIOUtils::round($h->temperature) . 
        " : precip type =  "      . $h->precipType.  
        " : pressure = "          . ForecastIOUtils::millibars_to_inches($h->pressure) . " in. " .
        " : wind direction = "    . ForecastIOUtils::degrees_to_cardinal($h->windBearing) .  
        " : wind speed = "        . ForecastIOUtils::round($h->windSpeed) . " mph " .  
        "\n";
    }
}


print "\nMinute by Minute Forecast - Next Hour\n";

my @minutely = $forecast->minutely;
if ( @minutely ) {
    foreach my $m ( @minutely ) {
        print ForecastIOUtils::format_date( $m->time ) . 
        " : " . $m->precipProbability * 100 . "% chance " .  
        " : " . ForecastIOUtils::calc_intensity($m->precipIntensity) . 
        " : " . $m->precipType . "\n";
    }
}


print "\nDaily Forecast - Next 7 Days\n";
my @daily = $forecast->daily;
if ( @daily ) {
    foreach my $d ( @daily ) {
        print "                      date = " . ForecastIOUtils::format_date( $d->time ) . "\n";
        print "                      icon = " . $d->icon . "\n";
        print "                   sunrise = " . ForecastIOUtils::format_date($d->sunriseTime) . "\n";
        print "                    sunset = " . ForecastIOUtils::format_date($d->sunsetTime) . "\n";
        print "          cloud cover desc = " . ForecastIOUtils::cloud_cover_description($d->cloudCover) . "\n";
        print "               precip type = " . $d->precipType . "\n";
        print "      max precip intensity = " . ForecastIOUtils::calc_intensity($d->precipIntensityMax) . "\n";
        print " max precip intensity time = " . ForecastIOUtils::format_date($d->precipIntensityMaxTime) . "\n";
        print "       precip accumulation = " . $d->precipAccumulation . "\n";
        print "                  low temp = " . ForecastIOUtils::round($d->temperatureMin) . "\n";
        print "             low temp time = " . ForecastIOUtils::format_date($d->temperatureMinTime) . "\n";
        print "                 high temp = " . ForecastIOUtils::round($d->temperatureMax) . "\n";
        print "            high temp time = " . ForecastIOUtils::format_date($d->temperatureMaxTime) . "\n";
        print "                wind speed = " . ForecastIOUtils::round($d->windSpeed) . " mph\n";
        print "            wind direction = " . ForecastIOUtils::degrees_to_cardinal($d->windBearing) . "\n";
        print "\n";
    }
}


print "\nHigh Level Info\n";
print "         time zone offset = " . $forecast->offset . "\n";
print "                 timezone = " . $forecast->timezone . "\n";
print "           hourly summary = " . $forecast->hourlysummary . "\n";
print "            daily summary = " . $forecast->dailysummary . "\n";
print "         minutely summary = " . $forecast->minutelysummary . "\n";
print "         Current date time: " . ForecastIOUtils::format_date() . "\n";
    
