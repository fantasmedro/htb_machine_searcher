#!/bin/bash
link="https://htbmachines.github.io/bundle.js"
archivo="bundle.js"

# Definimos el panel de ayuda
function helpPanel() {
        echo -e "[+] Uso:"
	echo -e "\tm) Busca la máquina por su nombre"
	echo -e "\ti) Busca la máquina por su dirección IP"
	echo -e "\tu) Descarga y actualización del fichero \"bundle.js\""
	echo -e "\ty) Busca el link de youtube de una máquina dada"
	echo -e "\td) Muestra el nombre de las máquinas de la dificultad dada"
	echo -e "\to) Muestra el nombre de las máquinas del sistema operativo dado"
	echo -e "\ts) Muestra el nombre de las máquinas con la skil dada"
	echo -e "\th) Activa el panel de ayuda"
}

# Descarga y actualización del archivo
function downloadUpdateFile() {
	if [ ! -f $archivo ]; then
		echo -e "[+] Descargando..."
		curl $link | js-beautify > $archivo
	else
		echo -e "[+] Comprobando si hay novedades"
		curl $link | js-beautify > bundle_temp.js
		old=$(md5sum bundle.js | awk '{print $1}')
	      	new=$(md5sum bundle_temp.js | awk '{print $1}')
		
		if [ "$old" == "$new" ]; then
			echo "[+] No hay ninguna novedad"
			rm bundle_temp.js
		else
			echo -e "[+] Actualizando el fichero..."
			cat bundle_temp.js > bundle.js
			rm bundle_temp.js
		fi
	fi	
}

# Búsqueda de máquina por nombre
function searchByName() {
	entrada="$1"
	name="$(cat $archivo | grep "name: \""$entrada"\"" | awk -F'"' '{print $2}')"
	
	if [ -z $name ]; then
		echo "[!] This machine does not exist or the name is misspeled"
	else
		echo -e "\n\tNombre: $name"

		datos=$(cat $archivo | grep -A 10 $entrada)

		echo -e "\tIP: $(echo -e "$datos" | head -n 4 |tail -n 1 | awk -F'"' '{print $2}')"

		echo -e "\tSistema Operativo: $(echo -e "$datos" | head -n 5 |tail -n 1 | awk -F'"' '{print $2}')"

		echo -e "\tDificultad: $(echo -e "$datos" | head -n 6 |tail -n 1 | awk -F'"' '{print $2}')"

		echo -e "\tSkills: $(echo -e "$datos" | head -n 7 |tail -n 1 | awk -F'"' '{print $2}')"

		echo -e "\tCertificaciones: $(echo -e "$datos" | head -n 8 |tail -n 1 | awk -F'"' '{print $2}')"

		echo -e "\tLink: $(echo -e "$datos" | head -n 9 |tail -n 1 | awk -F'"' '{print $2}')"

		opcion="$(echo -e "$datos" | head -n 10 | tail -n 1 | awk -F'"' '{print $1}' | sed 's/:/ /g' | sed 's/ //g')"
		
		if [ "$opcion" == "activeDirectory" ];then
			echo -e "\tDirectorio Activo:Sí"
			resuelta="$(echo -e "$datos" | head -n 11 |tail -n 1 | awk -F': ' '{print $2}' | sed 's/ //g')"
			
			if [ "$resuelta" == '!0' ];then
				
				echo -e "\tResuelta: Sí \n"
			else
				echo -e "\tResuelta: No \n"
			fi
		else
			resuelta="$(echo -e "$datos" | head -n 10 |tail -n 1 | awk -F': ' '{print $2}' | sed 's/ //g' )"
			
			echo -e "\tDirectorio Arctivo: No"

                        if [ "$resuelta" == '!0' ];then

                                echo -e "\tResuelta: Sí \n"
                        else
                                echo -e "\tResuelta: No \n"
                        fi


		fi
	fi	
}

# Búsqueda de máquina por dirección ip
function searchByIP() {
	entradaIp=$1
	pruebaIP=$(cat $archivo | grep -B 3 "$entradaIp" | grep name | tr -d '"|,' |awk '{print $NF}' )
	
	if [ "$pruebaIP" ]; then
		cat $archivo | grep -B 3 "$entradaIp" | grep name | tr -d '"|,' |awk '{print $NF}' |while read line;do echo -e "\nLa máquina, cuya dirección IP es $entradaIp, es \"$line\".";  entrada="$line"; echo -e "\nCuyos datos son:  \t $(searchByName $entrada)";done

	else
		echo "[!] The IP forwarded does not correspond to any machine"
	fi
}

function getYoutubeLink {
	machineName="$1"
	machineExist=$(cat $archivo | grep $machineName)
	if [ "$machineExist" ];then
		link=$(cat $archivo | awk "/name: \"$machineName\"/,/resuelta:/" | grep youtube | tr -d '"|,' | awk '{print $NF}')
	      echo "El link de la máquina $machineName es $link"
	else
		echo -e "[!] This machine does not exist"
	fi
}


function getMachinesByDifficulty {
	dificultad="$1"
	dificultadExiste=$(cat $archivo | grep "dificultad: \"$dificultad\",")
	
	if [ "$dificultadExiste" ]; then
		echo "hello"
		cat $archivo | grep "dificultad: \"$dificultad\"" -B 5| grep name | awk 'NF{print $NF}' | tr -d '"|,' | column
	else
		echo -e "[!] The given difficulty is not a valid option."
	fi
}

function getMachinesByOs() {
	os="$1"
	osExist=$(cat $archivo | grep "so: \"$os\",")

	if [ "$osExist" ]; then
		
		echo -e "Las máquinas con os $os, son:\n"
		cat $archivo | grep "so: \"$os\"" -B 5 | grep name | tr -d '"|,' | awk 'NF{print $NF}' | column
	else
		echo -e "No machine supports this os"
	fi
} 

function getMachinesByOsDifficulty() {
	os="$1"
	dificultad="$2"
	osExist=$(cat $archivo | grep "so: \"$os\",")
	dificultadExist=$(cat $archivo | grep "dificultad: \"$dificultad\",")

	if [ "$osExist" ] && [ "$dificultadExist" ];then	
		echo -e "Las máquinas de so $os y dificultad $dificultad"
		cat $archivo | grep "so: \"$os\"" -C 4 | grep -B 5 "dificultad: \"$dificultad\"" | grep "name: " | tr -d '"|,' | awk 'NF{print $NF}' | column
	else
		echo -e "[!] There are not machines with os $os and difficulty $dificultad."
	fi
}

function getMachinesBySkill() {
	skill="$1"
	skillExist=$(cat $archivo | grep -i "$skill")

	if [ "$skillExist" ]; then
		cat $archivo |grep "skills: " -B 6 | grep -i -B 6 "$skill" | grep "name: " | tr -d '"|,' | awk 'NF{print $NF}' | column	
	else
		echo -e "[!] The skill provided does not match any of the skills present in the machines"
	fi
}

# We declare a counter to choose which function to use
declare -i parameter_counter=0

# We declare indicators
declare -i indicator_os=0
declare -i inicator_difficulty=0

while getopts "n:i:y:d:o:s:uh" args; do
	case $args in
		n) entrada=$OPTARG; let parameter_counter+=1;;
		i) entradaIp=$OPTARG; let parameter_counter+=2;;
		u) let parameter_counter+=3;;
		y) machineName=$OPTARG; let parameter_counter+=4;;
		d) dificultad=$OPTARG; indicator_difficulty=1;let parameter_counter+=5;;
		o) os=$OPTARG; indicator_os=1; let parameter_counter+=6;;
		s) skill=$OPTARG; let parameter_counter+=7;;
		h) ;;
	esac
done

if [ $parameter_counter -eq 1 ];   then
	searchByName $entrada
elif [ $parameter_counter -eq 2 ]; then
	searchByIP $entradaIp
elif [ $parameter_counter -eq 3 ]; then
	downloadUpdateFile
elif [ $parameter_counter -eq 4 ]; then
	getYoutubeLink $machineName
elif [ $parameter_counter -eq 5 ]; then
	getMachinesByDifficulty $dificultad
elif [ $parameter_counter -eq 6 ]; then
	getMachinesByOs $os
elif [ $indicator_os -eq 1 ] && [ $indicator_difficulty -eq 1 ]; then
	getMachinesByOsDifficulty $os $dificultad
elif [ $parameter_counter -eq 7 ]; then
	getMachinesBySkill "$skill"
else
	helpPanel
fi
