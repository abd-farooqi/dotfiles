#!/bin/bash

ICON="󰥔"
CACHE_FILE="/tmp/prayer_api_cache.json"
LOCATION_CACHE="/tmp/prayer_location.cache"
CACHE_TTL=3600

PRAYER_ORDER=(Fajr Dhuhr Asr Maghrib Isha)

declare -A SHORT
SHORT[Fajr]="F"
SHORT[Dhuhr]="D"
SHORT[Asr]="A"
SHORT[Maghrib]="M"
SHORT[Isha]="I"

declare -A FULL
FULL[Fajr]="Fajr (Dawn)"
FULL[Dhuhr]="Dhuhr (Noon)"
FULL[Asr]="Asr (Afternoon)"
FULL[Maghrib]="Maghrib (Sunset)"
FULL[Isha]="Isha (Night)"

get_location() {
    if [[ -f "$LOCATION_CACHE" && $(( $(date +%s) - $(stat -c %Y "$LOCATION_CACHE") )) -lt 86400 ]]; then
        source "$LOCATION_CACHE"
        return
    fi
    CITY=$(curl -sf ipinfo.io/city 2>/dev/null)
    COUNTRY_CODE=$(curl -sf ipinfo.io/country 2>/dev/null)
    [[ -z "$CITY" ]] && CITY=$(curl -sf https://ipapi.co/city 2>/dev/null)
    [[ -z "$COUNTRY_CODE" ]] && COUNTRY_CODE=$(curl -sf https://ipapi.co/country 2>/dev/null)
    if [[ -n "$CITY" && -n "$COUNTRY_CODE" ]]; then
        echo "CITY='$CITY'" > "$LOCATION_CACHE"
        echo "COUNTRY_CODE='$COUNTRY_CODE'" >> "$LOCATION_CACHE"
    fi
}

get_data() {
    local today cache_key
    today=$(date +%Y-%m-%d)
    cache_key="${CACHE_FILE}.${today}"

    if [[ -f "$cache_key" && $(( $(date +%s) - $(stat -c %Y "$cache_key") )) -lt $CACHE_TTL ]]; then
        cat "$cache_key"
        return 0
    fi

    if [[ -z "$CITY" || -z "$COUNTRY_CODE" ]]; then
        return 1
    fi

    local data
    data=$(curl -sfL "https://api.aladhan.com/v1/timingsByCity?city=${CITY}&country=${COUNTRY_CODE}&method=1" 2>/dev/null)
    if [[ -n "$data" ]]; then
        echo "$data" > "$cache_key"
        echo "$data"
        return 0
    fi

    local yesterday
    yesterday=$(date -d "1 day ago" +%Y-%m-%d 2>/dev/null)
    if [[ -f "${CACHE_FILE}.${yesterday}" ]]; then
        cat "${CACHE_FILE}.${yesterday}"
        return 0
    fi

    return 1
}

to_min() {
    local IFS=: h m
    read -r h m <<< "$1"
    echo $((10#$h * 60 + 10#$m))
}

to_12h() {
    local IFS=: h m ampm
    read -r h m <<< "$1"
    if ((10#$h == 0)); then
        echo "12:$m AM"
    elif ((10#$h < 12)); then
        printf "%d:%s AM\n" $((10#$h)) "$m"
    elif ((10#$h == 12)); then
        echo "12:$m PM"
    else
        printf "%d:%s PM\n" $((10#$h - 12)) "$m"
    fi
}

get_location
DATA=$(get_data) || {
    printf '{"text":"%s ...","tooltip":"Prayer data unavailable","class":"error"}\n' "$ICON"
    exit 0
}

FAJR=$(echo "$DATA" | jq -r '.data.timings.Fajr // empty' 2>/dev/null)
DHUHR=$(echo "$DATA" | jq -r '.data.timings.Dhuhr // empty' 2>/dev/null)
ASR=$(echo "$DATA" | jq -r '.data.timings.Asr // empty' 2>/dev/null)
MAGHRIB=$(echo "$DATA" | jq -r '.data.timings.Maghrib // empty' 2>/dev/null)
ISHA=$(echo "$DATA" | jq -r '.data.timings.Isha // empty' 2>/dev/null)

if [[ -z "$FAJR$DHUHR$ASR$MAGHRIB$ISHA" ]]; then
    printf '{"text":"%s ERR","tooltip":"Failed to parse prayer times","class":"error"}\n' "$ICON"
    exit 0
fi

NOW=$(to_min "$(date +%H:%M)")

declare -A TIMES
TIMES[Fajr]=$(to_min "$FAJR")
TIMES[Dhuhr]=$(to_min "$DHUHR")
TIMES[Asr]=$(to_min "$ASR")
TIMES[Maghrib]=$(to_min "$MAGHRIB")
TIMES[Isha]=$(to_min "$ISHA")

NEXT_NAME=""
NEXT_TIME=99999
CUR_NAME=""

for p in "${PRAYER_ORDER[@]}"; do
    pt=${TIMES[$p]}
    (( pt <= NOW )) && CUR_NAME=$p
    if (( pt > NOW && pt < NEXT_TIME )); then
        NEXT_TIME=$pt
        NEXT_NAME=$p
    fi
done

if [[ -z "$NEXT_NAME" ]]; then
    NEXT_NAME="Fajr"
    NEXT_TIME=$(( TIMES[Fajr] + 1440 ))
    CUR_NAME="Isha"
fi

[[ -z "$CUR_NAME" ]] && CUR_NAME="—"

REMAINING=$(( NEXT_TIME - NOW ))
COUNTDOWN=$(printf "%02d:%02d" $((REMAINING/60)) $((REMAINING%60)))

CITY_DISPLAY="${CITY:-Unknown}"

TEXT="$ICON"

SEP="─────────────────────────"
TOOLTIP="${SEP}\n"
TOOLTIP+="  Prayer Times — ${CITY_DISPLAY}\n"
TOOLTIP+="${SEP}\n"
TOOLTIP+="  Current: ${CUR_NAME}\n"
TOOLTIP+="  Next:    ${FULL[$NEXT_NAME]} in ${COUNTDOWN}\n"
TOOLTIP+="${SEP}\n"
for p in "${PRAYER_ORDER[@]}"; do
    case $p in Fajr) T=$FAJR ;; Dhuhr) T=$DHUHR ;; Asr) T=$ASR ;; Maghrib) T=$MAGHRIB ;; Isha) T=$ISHA ;; esac
    T12=$(to_12h "$T")
    m=""
    [[ "$p" == "$CUR_NAME" ]] && m=" ◄"
    TOOLTIP+="  ${FULL[$p]}: ${T12}${m}\n"
done

CLASS=$(echo "$NEXT_NAME" | tr '[:upper:]' '[:lower:]')

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS"
