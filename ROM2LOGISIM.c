#include <stdio.h>
#include <string.h>

int main(int argc, char **argv){
	FILE *trueHex;
	FILE *logiCrap;
	char buffer[255];
	unsigned char hex;
	long lSize;
	int i;
	
	if(argc<3){
		printf("Falta parametro!!\n");
		return -1;
	}
	trueHex = fopen(argv[1],"rb");
	if(!trueHex){
		printf("Falha em abrir o arquivo!!\n");
		return -1;
	}
	logiCrap= fopen(argv[2],"wb");
	if(!logiCrap){
		printf("Falha em gravar o arquivo!!\n");
		return -1;
	}
	//Pega o tamanho do arquivo
	fseek (trueHex , 0 , SEEK_END);
	lSize = ftell (trueHex);
	rewind (trueHex);
	//Gravar cabeçalho
	sprintf(buffer,"v2.0 raw\n");
	fwrite(buffer,strlen(buffer),1,logiCrap);
	for(i=0;i<lSize;i++){
		fread(&hex,1,1,trueHex);
		sprintf(buffer,"%x ",hex);
		fwrite(buffer,strlen(buffer),1,logiCrap);
	}
	sprintf(buffer,"\n");
	fwrite(buffer,strlen(buffer),1,logiCrap);
	fclose(trueHex);
	fclose(logiCrap);
};
