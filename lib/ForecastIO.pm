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

    my @ALERTS = qw( alert_title alert_uri alert_expires );
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

    use Weather::DateTimeFormatter;
   
    sub format_date {
        my $epoch = shift;
        my $format_string = shift;
        $format_string = "(12hr):(0min) (a.p.) (TZ) (dayname), (monthname) (daynum), (yearfull)" if !$format_string;
        $epoch = time() if !$epoch or !is_numeric($epoch);
        return DateTimeFormatter::create_date_time_stamp_local($format_string, $epoch);
    }

    sub is_numeric {
        my $str = shift;
        my $rc = 0;
        if ( $str =~ m|^[0-9]+$| ) {
            $rc = 1;
        }
        return $rc;
    }

    # barometric pressure conversion
    sub millibars_to_inches {
        my $mb = shift;
        return sprintf "%.2f", $mb * 0.0295301;
    }

    # wind direction conversion from say 180 to S (south)
    sub degrees_to_cardinal {
        my $degrees = shift;
        my @cardinal_arr = qw(N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW);
        my $val = int(($degrees/22.5)+.5);
        my $idx = $val % 16;
        return $cardinal_arr[$idx];
    }

    # wind speed conversion
    sub meters_per_second_to_mph {
        my $ms = shift;
        my $mph = $ms * 2.23694;   
        return int($mph + $mph/abs($mph*2));
    }

    sub round {
        my $number = shift;
        return int($number + .5 * ($number <=> 0));
    }

}

1;

