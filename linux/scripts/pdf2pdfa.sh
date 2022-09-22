#!/bin/bash

SCRIPTNAME=${0##*/}

exist_commnad() {
    command -v $1 >/dev/null 2>&1 || { echo >&2 "$SCRIPTNAME requires $1 but it's not installed. Aborting."; exit 30; }
}

exit_command() {
    if [ $? -ne 0 ]; then { echo "Failed, aborting." ; exit 40; } fi
}

PDF=$1
PS=${PDF%.*}.ps
PDFA=${PDF%.*}_a.pdf

PDFTOPS=pdftops
GS=gs

exist_commnad $PDFTOPS
exist_commnad $GS

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters."
    echo "Usage: $SCRIPTNAME PDF_FILE"
    exit 10
fi

if [ ! -f "$PDF" ]; then
    echo "$PDF does not exist."
    exit 20
fi

echo "PDF -> PS (${PDF} -> ${PS})"
$PDFTOPS "${PDF}" "${PS}"
exit_command

echo "PS -> PDF/A (${PS} -> ${PDFA})"
$GS -q -dPDFA -dBATCH -dNOPAUSE -dNOOUTERSAVE -dNOSAFER -sProcessColorModel=DeviceCMYK -sDEVICE=pdfwrite -sPDFACompatibilityPolicy=1 -sOutputFile="${PDFA}" "${PS}"
exit_command

rm -f "${PS}"

exit 0

# ~@:-]
