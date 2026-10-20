#!/usr/bin/env bash

# Prints the current weather for eww as {"icon": ..., "temp": ..., "tooltip":
# ...}: a Nerd Font icon for the sky, the temperature in °F, and details for
# the tooltip. From Open-Meteo (free, no API key), at the location that
# colorscheme-solar caches from ipinfo.io.
#
# Weather sends no events, so this is one long-lived loop rather than a
# defpoll: it fetches every 15 minutes (how often Open-Meteo updates), and
# early when NetworkManager comes online, e.g. after a suspend, which a timer
# doesn't count. A failed fetch keeps the last reading for up to an hour and
# retries after a minute.
source "${BASH_SOURCE%/*}/lib.sh"

location_cache=~/.cache/colorscheme-solar/location.json

# Nerd Font (Material Design) icons
sunny_icon=$'\U000F0599'
night_icon=$'\U000F0594'
partly_cloudy_icon=$'\U000F0595'
night_partly_cloudy_icon=$'\U000F0F31'
cloudy_icon=$'\U000F0590'
fog_icon=$'\U000F0591'
rainy_icon=$'\U000F0597'
pouring_icon=$'\U000F0596'
snowy_icon=$'\U000F0598'
snowy_rainy_icon=$'\U000F067F'
lightning_rainy_icon=$'\U000F067E'
unavailable_icon=$'\U000F0F2F'

# Print "LAT,LON": colorscheme-solar's, or ipinfo.io's if it has none yet
location() {
    { jq -er .loc "$location_cache" ||
        curl -sf --max-time 10 https://ipinfo.io/json | jq -er .loc; } 2>/dev/null
}

# Set icon and sky for a WMO weather code (CODE IS_DAY), as Open-Meteo gives
condition() {
    local clear_icon=$night_icon partly_icon=$night_partly_cloudy_icon
    if (( $2 == 1 )); then
        clear_icon=$sunny_icon partly_icon=$partly_cloudy_icon
    fi
    case $1 in
        0) sky="Clear" icon=$clear_icon ;;
        1) sky="Mainly clear" icon=$partly_icon ;;
        2) sky="Partly cloudy" icon=$partly_icon ;;
        3) sky="Overcast" icon=$cloudy_icon ;;
        45|48) sky="Fog" icon=$fog_icon ;;
        51|53|55) sky="Drizzle" icon=$rainy_icon ;;
        56|57) sky="Freezing drizzle" icon=$snowy_rainy_icon ;;
        61|63) sky="Rain" icon=$rainy_icon ;;
        65) sky="Heavy rain" icon=$pouring_icon ;;
        66|67) sky="Freezing rain" icon=$snowy_rainy_icon ;;
        71|73|75|77) sky="Snow" icon=$snowy_icon ;;
        80|81) sky="Rain showers" icon=$rainy_icon ;;
        82) sky="Heavy showers" icon=$pouring_icon ;;
        85|86) sky="Snow showers" icon=$snowy_icon ;;
        95) sky="Thunderstorm" icon=$lightning_rainy_icon ;;
        96|99) sky="Thunderstorm with hail" icon=$lightning_rainy_icon ;;
        *) sky="Unknown" icon=$cloudy_icon ;;
    esac
}

# Fetch the weather and print it; fails, printing nothing, if it can't
render() {
    local loc data code is_day sky icon json
    loc=$(location) || return
    data=$(curl -sf --max-time 10 "https://api.open-meteo.com/v1/forecast?latitude=${loc%,*}&longitude=${loc#*,}&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min&forecast_days=1&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto") || return
    read -r code is_day < <(jq -r '.current | "\(.weather_code) \(.is_day)"' <<<"$data")
    [[ $code =~ ^[0-9]+$ && $is_day =~ ^[01]$ ]] || return
    condition "$code" "$is_day"
    # round turns -0.4 into -0, hence the + 0
    json=$(jq -ce --arg icon "$icon" --arg sky "$sky" '
        def deg: round + 0 | "\(.)°";
        .current as $c | .daily as $d |
        {icon: $icon,
         temp: "\($c.temperature_2m | deg)F",
         tooltip: ([$sky,
                    "Feels like \($c.apparent_temperature | deg)F",
                    "High \($d.temperature_2m_max[0] | deg) · Low \($d.temperature_2m_min[0] | deg)",
                    "Wind \($c.wind_speed_10m | round) mph · Humidity \($c.relative_humidity_2m)%"]
                   | join("\n"))}' <<<"$data" 2>/dev/null) || return
    emit "$json"
}

# Wait SECONDS, or less if NetworkManager comes online meanwhile.
wait_for_refresh() {
    local deadline=$(( SECONDS + $1 )) line
    while (( SECONDS < deadline )); do
        if read -r -t $(( deadline - SECONDS )) -u "$events" line; then
            case $line in
                *"now in the 'connected' state"*|*"Connectivity is now 'full'"*)
                    drain_burst <&"$events"
                    return ;;
            esac
        elif (( $? <= 128 )); then
            # Not a timeout but the end: nmcli monitor exited (NetworkManager
            # isn't running), so just wait
            sleep $(( deadline - SECONDS ))
            return
        fi
    done
}

# NetworkManager's state changes, in English to match the patterns above
exec {events}< <(LC_ALL=C nmcli monitor 2>/dev/null)

fetched=
while :; do
    if render; then
        fetched=$SECONDS
        wait_for_refresh 900
    else
        if [[ -z $fetched ]] || (( SECONDS - fetched > 3600 )); then
            emit "$(jq -nc --arg icon "$unavailable_icon" \
                '{$icon, temp: "--", tooltip: "Weather unavailable"}')"
        fi
        wait_for_refresh 60
    fi
done
