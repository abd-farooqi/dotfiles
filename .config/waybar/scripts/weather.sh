#!/bin/bash

CACHE_FILE="/tmp/weather_api_cache.json"
LOCATION_CACHE="/tmp/weather_location.cache"
CACHE_TTL=1800

get_location() {
    if [[ -f "$LOCATION_CACHE" && $(( $(date +%s) - $(stat -c %Y "$LOCATION_CACHE") )) -lt 86400 ]]; then
        source "$LOCATION_CACHE"
        return
    fi
    CITY=$(curl -sf ipinfo.io/city 2>/dev/null)
    COUNTRY_CODE=$(curl -sf ipinfo.io/country 2>/dev/null)
    LOC=$(curl -sf ipinfo.io/loc 2>/dev/null)
    [[ -z "$CITY" ]] && CITY=$(curl -sf https://ipapi.co/city 2>/dev/null)
    [[ -z "$COUNTRY_CODE" ]] && COUNTRY_CODE=$(curl -sf https://ipapi.co/country 2>/dev/null)
    [[ -z "$LOC" ]] && LOC=$(curl -sf https://ipapi.co/loc 2>/dev/null)
    if [[ -n "$CITY" && -n "$COUNTRY_CODE" ]]; then
        > "$LOCATION_CACHE"
        echo "CITY='$CITY'" >> "$LOCATION_CACHE"
        echo "COUNTRY_CODE='$COUNTRY_CODE'" >> "$LOCATION_CACHE"
        echo "LOC='$LOC'" >> "$LOCATION_CACHE"
    fi
}

get_loc() {
    LOC=$(curl -sf ipinfo.io/loc 2>/dev/null)
    [[ -z "$LOC" ]] && LOC=$(curl -sf https://ipapi.co/loc 2>/dev/null)
    if [[ -n "$LOC" && -f "$LOCATION_CACHE" ]]; then
        if ! grep -q "LOC=" "$LOCATION_CACHE"; then
            echo "LOC='$LOC'" >> "$LOCATION_CACHE"
        fi
    fi
}

get_data() {
    if [[ -f "$CACHE_FILE" && $(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") )) -lt $CACHE_TTL ]]; then
        cat "$CACHE_FILE"
        return 0
    fi
    if [[ -z "$LOC" ]]; then return 1; fi
    local lat="${LOC%,*}" lon="${LOC#*,}"
    local data
    data=$(curl -sf "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,uv_index&timezone=auto" 2>/dev/null)
    if [[ -n "$data" ]]; then
        echo "$data" > "$CACHE_FILE"
        echo "$data"
        return 0
    fi
    return 1
}

wmo_icon() {
    case $1 in
        0) echo "󰖨" ;; 1|2|3) echo "󰅟" ;; 45|48) echo "󰖑" ;;
        51|53|55|56|57) echo "󰖗" ;; 61|63|65|66|67) echo "󰖖" ;;
        71|73|75|77) echo "󰖘" ;; 80|81|82) echo "󰼱" ;;
        85|86) echo "󰖘" ;; 95|96|99) echo "󰙾" ;;
        *) echo "󰅟" ;;
    esac
}

wmo_desc() {
    case $1 in
        0) echo "Clear" ;; 1) echo "Mainly Clear" ;; 2) echo "Partly Cloudy" ;;
        3) echo "Overcast" ;; 45) echo "Foggy" ;; 48) echo "Depositing Rime Fog" ;;
        51) echo "Light Drizzle" ;; 53) echo "Moderate Drizzle" ;; 55) echo "Dense Drizzle" ;;
        56) echo "Freezing Drizzle" ;; 57) echo "Dense Freezing Drizzle" ;;
        61) echo "Slight Rain" ;; 63) echo "Moderate Rain" ;; 65) echo "Heavy Rain" ;;
        66) echo "Freezing Rain" ;; 67) echo "Heavy Freezing Rain" ;;
        71) echo "Slight Snow" ;; 73) echo "Moderate Snow" ;; 75) echo "Heavy Snow" ;;
        77) echo "Snow Grains" ;; 80) echo "Slight Rain Showers" ;;
        81) echo "Moderate Rain Showers" ;; 82) echo "Violent Rain Showers" ;;
        85) echo "Slight Snow Showers" ;; 86) echo "Heavy Snow Showers" ;;
        95) echo "Thunderstorm" ;; 96) echo "Thunderstorm w/ Hail" ;;
        99) echo "Thunderstorm w/ Heavy Hail" ;; *) echo "Unknown" ;;
    esac
}

get_location
get_loc
[[ -f "$LOCATION_CACHE" ]] && source "$LOCATION_CACHE"
DATA=$(get_data) || {
    printf '{"text":"󰅟","tooltip":"Weather unavailable","class":"error"}\n'
    exit 0
}

TEMP=$(echo "$DATA" | jq -r '.current.temperature_2m // "?"' 2>/dev/null)
FEELS=$(echo "$DATA" | jq -r '.current.apparent_temperature // "?"' 2>/dev/null)
HUMID=$(echo "$DATA" | jq -r '.current.relative_humidity_2m // "?"' 2>/dev/null)
WIND=$(echo "$DATA" | jq -r '.current.wind_speed_10m // "?"' 2>/dev/null)
UV=$(echo "$DATA" | jq -r '.current.uv_index // "?"' 2>/dev/null)
CODE=$(echo "$DATA" | jq -r '.current.weather_code // 0' 2>/dev/null)

ICON=$(wmo_icon "$CODE")
DESC=$(wmo_desc "$CODE")
CITY_DISPLAY="${CITY:-Unknown}"

TEXT="${ICON}"

SEP="─────────────────────────"
TOOLTIP="${SEP}\n"
TOOLTIP+="  Weather — ${CITY_DISPLAY}\n"
TOOLTIP+="${SEP}\n"
TOOLTIP+="  ${DESC}, ${TEMP}° (feels ${FEELS}°)\n"
TOOLTIP+="  Humidity: ${HUMID}%\n"
TOOLTIP+="  Wind: ${WIND} km/h\n"
TOOLTIP+="  UV Index: ${UV}\n"
TOOLTIP+="${SEP}"

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$TEXT" "$TOOLTIP" ""
