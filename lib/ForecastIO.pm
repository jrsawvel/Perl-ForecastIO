use strict;
use warnings;
use NEXT;

{
    package ForecastIO;

    use JSON::PP;
    use LWP::Simple;

    my $API_ENDPOINT = "https://api.forecast.io/forecast/";

    my @FIELDS = qw( latitude longitude api_key api_url data timezone offset hourlysummary dailysummary minutelysummary ); 
    foreach my $field (@FIELDS) {
        no strict 'refs';
        *$field = sub {
            my $self = shift;
            $self->{$field} = shift if @_;
            return $self->{$field};
        };
    }

    my @INTERVALS = qw( daily hourly minutely );
    foreach my $interval (@INTERVALS) {
        no strict 'refs';
        *$interval = sub {
            my $self = shift;
            my $tmp_ly = $self->{data}->{$interval}->{'data'};
            my @interval_arr;
            foreach my $i ( @$tmp_ly ) {
                push (@interval_arr, ForecastIOConditions->new($i));
            }
            return @interval_arr; 
        };
    }

    sub new {
        my ($class, $api_key, $latitude, $longitude) = @_;
        my $self = ();
        $self->{latitude}  = $latitude;
        $self->{longitude} = $longitude;
        $self->{api_key}   = $api_key;
        $self->{api_url}   = $API_ENDPOINT . $api_key . "/" . $latitude . "," . $longitude;
        bless($self, $class);                 
        return $self;
    }

    sub currently {
        my ($self) = @_;
        return ForecastIOConditions->new($self->{data}->{'currently'});
    }

    sub alerts {
        my ($self) = @_;
        my $tmp_alerts = $self->{data}->{'alerts'};
        my @alerts;
        foreach my $a ( @$tmp_alerts ) {
            push (@alerts, ForecastIOConditions->new($a));
        }
        return @alerts; 
    }

    #### download json and convert json into perl var
    sub fetch_data {
        my ($self, $dt) = @_;
        my $tmp_url = $self->{api_url};
        $tmp_url = $self->{api_url} . "," . $dt if $dt;
        my $json_text = get($tmp_url);
        return 0 if !$json_text;
        $self->{data} = decode_json $json_text;
        # get some top-level key-value pairs
        $self->{timezone}        = defined($self->{data}->{'timezone'})              ? $self->{data}->{'timezone'} : "undef"; 
        $self->{offset}          = defined($self->{data}->{'offset'})                ? $self->{data}->{'offset'} : "undef"; 
        $self->{hourlysummary}   = defined($self->{data}->{'hourly'}->{'summary'})   ? $self->{data}->{'hourly'}->{'summary'} : "undef"; 
        $self->{dailysummary}    = defined($self->{data}->{'daily'}->{'summary'})    ? $self->{data}->{'daily'}->{'summary'} : "undef"; 
        $self->{minutelysummary} = defined($self->{data}->{'minutely'}->{'summary'}) ? $self->{data}->{'minutely'}->{'summary'} : "undef"; 
    }

    ##### set methods ####

    sub DESTROY {
        my ($self) = @_;
        $self->EVERY::_destroy;
    }

    sub _destroy {
        my ($self) = @_;
        delete $self->{data};
    }
}

{
    package ForecastIOConditions;

    # OO Getters/Setters   http://www.perlmonks.org/?node_id=317885
    my @FIELDS = qw( windBearing icon visibility pressure time precipType precipIntensity windSpeed precipIntensityError cloudCover summary dewPoint precipProbability ozone humidity temperature temperatureMax sunsetTime temperatureMin precipIntensityMax  precipIntensityMaxTime temperatureMaxTime temperatureMinTime sunriseTime precipAccumulation );  # Put your field names here
    foreach my $field (@FIELDS) {
        no strict 'refs';
        *$field = sub {
            my $self = shift;
            # no need for setter:   $self->{$field} = shift if @_;
            if ( exists $self->{raw_data}->{$field} ) {
                return $self->{raw_data}->{$field};
            } else {
                return "undef";
            }
        };
    }

    my @ALERTS = qw( alert_title alert_uri alert_expires alert_description );
    foreach my $alert_part (@ALERTS) {
        no strict 'refs';
        *$alert_part = sub {
            my $self = shift;
            my @a = split('_', $alert_part);  
            return $self->{raw_data}->{$a[1]};
        };
    }

    sub new {
        my ($class, $raw_data) = @_;
        my $self = ();
        $self->{raw_data} = $raw_data;
        bless($self, $class);
        return $self;
    }
}

{
    package ForecastIOUtils;

    use Time::Local;
  
    # The UNIX time (that is, seconds since midnight GMT on 1 Jan 1970)  
    sub format_date {
        my $epoch = shift;
        return $epoch if $epoch and $epoch eq "undef"; # forecast.io value
        $epoch = time() if !$epoch; # no epoch secs passed to sub, so create current date and tim
        my ($sec, $min, $hr, $mday, $mon, $yr)  = (gmtime($epoch))[0,1,2,3,4,5];
        my $tmp_date = sprintf "%04d-%02d-%02d", 2000 + $yr-100, $mon+1, $mday;
        my $tmp_time = sprintf "%02d:%02d:%02d", $hr, $min, $sec;
        return $tmp_date . "T" . $tmp_time . "Z";
    }

    sub is_numeric {
        my $str = shift;
        my $rc = 0;
        if ( $str =~ m|^[0-9]+$| ) {
            $rc = 1;
        }
        return $rc;
    }

    sub is_float {
        my $str = shift;
        my $rc = 0;
        if ( $str =~ m|^[0-9\.]+$| ) {
            $rc = 1;
        }
        return $rc;
    }

    # barometric pressure conversion
    sub millibars_to_inches {
        my $mb = shift;
        return $mb if !is_float($mb);
        return sprintf "%.2f", $mb * 0.0295301;
    }

    # wind direction conversion from say 180 to S (south)
    sub degrees_to_cardinal {
        my $degrees = shift;
        return $degrees if !is_numeric($degrees);
        my @cardinal_arr = qw(N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW);
        my $val = int(($degrees/22.5)+.5);
        my $idx = $val % 16;
        return $cardinal_arr[$idx];
    }

    # wind speed conversion
    sub meters_per_second_to_mph {
        my $ms = shift;
        return $ms if !is_numeric($ms);
        my $mph = $ms * 2.23694;   
        return int($mph + $mph/abs($mph*2));
    }

    sub round {
        my $number = shift;
        return $number if $number eq "undef";
        return int($number + .5 * ($number <=> 0));
    }

    # from forecast.io api docs:
    # A value of 0 corresponds to clear sky, 
    # 0.4 to scattered clouds, 
    # 0.75 to broken cloud cover, 
    # and 1 to completely overcast skies.
    # also referencing:
    # http://forecast.weather.gov/glossary.php?word=SKY%20CONDITION
    # then creating my own break points.
    sub cloud_cover_description {
        my $cloud_cover = shift;    

        return $cloud_cover if !$cloud_cover or !is_float($cloud_cover);

        if ( $cloud_cover < .12 ) {
            return "clear";
        } elsif ( $cloud_cover >= .12 and $cloud_cover < .3 ) {
            return "mostly clear";
        } elsif ( $cloud_cover >= .3 and $cloud_cover < .625 ) {
            return "partly cloudy";
        } elsif ( $cloud_cover >= .625 and $cloud_cover <= .875 ) {
            return "mostly cloudy";
        } elsif ( $cloud_cover > .875 ) {
            return "cloudy";
        }
        return $cloud_cover;      
    }

    # https://developer.forecast.io/docs/v2
    #      precipIntensity: A numerical value representing the average expected intensity 
    #      (in inches of liquid water per hour) of precipitation occurring at the given 
    #      time conditional on probability (that is, assuming any precipitation occurs at all). 
    #      A very rough guide is that a value of 0 corresponds to no precipitation, 
    #      0.002 corresponds to very light precipitation, 
    #      0.017 corresponds to light precipitation, 
    #      0.1 corresponds to moderate precipitation, 
    #      and 0.4 corresponds to very heavy precipitation.
    sub calc_intensity {
        my $intensity = shift;

        my $str = "";

        return $intensity if !$intensity;

        # easier to understand with whole numbers
        $intensity = $intensity * 1000;

        if ( $intensity > 0 and $intensity < 17 ) {
            $str = "very light";
        } elsif ( $intensity >= 17 and $intensity < 50 ) {
            $str = "light";
        } elsif ( $intensity >= 50 and $intensity < 75 ) {
            $str = "light to moderate";
        } elsif ( $intensity >= 75 and $intensity < 125 ) {
            $str = "moderate";
        } elsif ( $intensity >= 125 and $intensity < 200 ) {
            $str = "moderate to heavy";
        } elsif ( $intensity >= 200 and $intensity < 299 ) {
            $str = "heavy";
        } elsif ( $intensity >= 300 and $intensity < 400 ) {
            $str = "heavy to very heavy";
        } elsif ( $intensity >= 400 ) {
            $str = "very heavy";
        }

        return $str;
    }

    sub calc_intensity_color {
        my $intensity = shift;

        my $str = "#000000;";

        return $str if !$intensity;

        # easier to understand with whole numbers
        $intensity = $intensity * 1000;

        if ( $intensity > 0 and $intensity < 17 ) {
            $str = "#c0c0c0;";   # very light
        } elsif ( $intensity >= 17 and $intensity < 50 ) {
            $str = "#888888;";   # light
        } elsif ( $intensity >= 50 and $intensity < 75 ) {
            $str = "#006600;";   # light to moderate
        } elsif ( $intensity >= 75 and $intensity < 125 ) {
            $str = "#cccc00;";   # moderate - dark green-yellow
        } elsif ( $intensity >= 125 and $intensity < 200 ) {
            $str = "#cc6600;";   # moderate to heavy - dark orange
        } elsif ( $intensity >= 200 and $intensity < 299 ) {
            $str = "#cc0000;";   # heavy - dark red
        } elsif ( $intensity >= 300 and $intensity < 400 ) {
            $str = "#990066;";   # heavy to very heavy - dark purple
        } elsif ( $intensity >= 400 ) {
            $str = "#000099;";   # very heavy - dark blue
        }

        return $str;
    }

}

1;

