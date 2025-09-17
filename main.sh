#!/bin/bash

function mainMenu() {
	select choice in "Create DB" "List Databases" "Connect To Database" "Drop Database";
	do
	case $choice in 
	"Create DB") createDb ; mainMenu;;
	"List Databases") listDB ; mainMenu ;;
	"Connect To Database") connectDB; mainMenu ;;
	"Drop Database") dropDB ; mainMenu ;;
	*) echo "Not one of the choices";;
	esac
	done
}

function OperationsMenu() {
	select choice in "Create Table" "List Tables" "Drop Table" "Insert Into Table" "Select From Table" "Return To Main Menu";
	do
	case $choice in 
	"Create Table") createTable; OperationsMenu;;
	"List Tables") listTables; OperationsMenu;;
	"Drop Table") dropTable; OperationsMenu;;
	"Insert Into Table") insertTable; OperationsMenu;;
	"Select From Table") selectTable; OperationsMenu;;
	"Return To Main Menu") cd ../.. ; mainMenu;;
	*) echo "Not one of the choices";;
	esac
	done
}

# ============= DB Functions =============

function createDb() {
	echo "DB name:"
	read name
	mkdir -p ./Databases/$name
	echo "DB created!"
}

function listDB() {
	ls ./Databases
}

function connectDB() {
	echo "DB name:"
	read name
	cd ./Databases/$name 2>/dev/null || { echo "Not found"; return; }
	OperationsMenu
}

function dropDB() {
	echo "DB name:"
	read name
	rm -rf ./Databases/$name
	echo "DB dropped!"
}

# ============= Table Functions =============

function createTable() {
	echo "Table name:"
	read tname
	echo "Primary key column name:"
	read pk
	echo "Primary key type (string/number):"
	read pkType
	header="$pk"
	types="$pkType"

	while true; do
		echo "Add another column? (y/n)"
		read ans
		if [ "$ans" == "y" ]; then
			echo "Column name:"
			read cname
			echo "Column type (string/number):"
			read ctype
			header="$header:$cname"
			types="$types:$ctype"
		else
			break
		fi
	done

	echo $header > $tname
	echo $types >> $tname
	echo "PRIMARY:$pk" >> $tname
	echo "Table created!"
}

function listTables() {
	ls
}

function dropTable() {
	echo "Table name:"
	read tname
	rm -f $tname
	echo "Table dropped!"
}

function insertTable() {
    echo "Table name:"
    read tname

    if [ ! -f "$tname" ]; then
        echo "Table not found!"
        return
    fi

    cols=$(head -n 1 "$tname")
    types=$(sed -n '2p' "$tname")
    pkName=$(sed -n '3p' "$tname" | cut -d: -f2)

    IFS=':' read -ra colArr <<< "$cols"
    IFS=':' read -ra typeArr <<< "$types"


    pkIndex=-1
    for i in "${!colArr[@]}"; do
        if [ "${colArr[$i]}" = "$pkName" ]; then
            pkIndex=$i
            break
        fi
    done

    row=""
    for i in "${!colArr[@]}"; do
        col="${colArr[$i]}"
        ctype="${typeArr[$i]}"

        read -p "Enter $col ($ctype): " val

        if [ "$ctype" = "number" ]; then
            if ! [[ $val =~ ^[0-9]+$ ]]; then
                echo "Invalid input: $col must be a number (digits only). Insert cancelled."
                return
            fi
        fi

        if [ $i -eq $pkIndex ]; then
            if cut -d: -f$((pkIndex+1)) "$tname" | tail -n +4 | grep -qx "$val"; then
                echo "Duplicate primary key '$val' detected. Insert cancelled."
                return
            fi
        fi

        row="${row}${val}:"
    done

    echo "${row%:}" >> "$tname"
    echo "Row inserted!"
}


function display() {
    file="$1"
    if [ ! -f "$file" ]; then
        echo "File not found!"
        return
    fi

    awk -F: '
    NR==1 {
        for (i=1; i<=NF; i++) {
            header[i]=$i
            w[i]=length($i)
        }
        next
    }
    NR==2 || NR==3 { next }
    {
        for (i=1; i<=NF; i++) {
            if (length($i) > w[i]) w[i]=length($i)
            data[NR,i]=$i
        }
        rows[NR]=$0
    }
    END {

        for (i=1; i<=length(header); i++) {
            printf " %-"w[i]"s ", header[i]
            if (i<NF) printf "|"
        }
        print ""

        for (i=1; i<=length(header); i++) {
            for (j=1; j<=w[i]+2; j++) printf "-"
            if (i<NF) printf "+"
        }
        print ""

        for (r=4; r<=NR; r++) {
            split(rows[r], vals, ":")
            for (i=1; i<=length(vals); i++) {
                printf " %-"w[i]"s ", vals[i]
                if (i<length(vals)) printf "|"
            }
            print ""
        }
    }' "$file"
}


function selectTable() {
	echo "Table name:"
	read tname
	if [ ! -f "$tname" ]; then
		echo "Table not found!"
		return
	fi
	display "$tname"
}

# ============= START =============
mkdir -p ./Databases
mainMenu