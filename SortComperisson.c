#include<stdio.h>
#include<stdlib.h>
#include <time.h>

#define GNUPLOT 1
#define INCREMENT 1
#define MAX_VECTOR 300

// Function to Merge Arrays L and R into A. 
// lefCount = number of elements in L
// rightCount = number of elements in R. 
void Merge(int *A,int *L,int leftCount,int *R,int rightCount) {
	int i,j,k;

	// i - to mark the index of left aubarray (L)
	// j - to mark the index of right sub-raay (R)
	// k - to mark the index of merged subarray (A)
	i = 0; j = 0; k =0;

	while(i<leftCount && j< rightCount) {
		if(L[i]  < R[j]) A[k++] = L[i++];
		else A[k++] = R[j++];
	}
	while(i < leftCount) A[k++] = L[i++];
	while(j < rightCount) A[k++] = R[j++];
}

// Recursive function to sort an array of integers. 
void MergeSort(int *A,int n) {
	int mid,i, *L, *R;
	if(n < 2) return; // base condition. If the array has less than two element, do nothing. 

	mid = n/2;  // find the mid index. 

	// create left and right subarrays
	// mid elements (from index 0 till mid-1) should be part of left sub-array 
	// and (n-mid) elements (from mid to n-1) will be part of right sub-array
	L = (int*)malloc(mid*sizeof(int)); 
	R = (int*)malloc((n- mid)*sizeof(int)); 
	
	for(i = 0;i<mid;i++) L[i] = A[i]; // creating left subarray
	for(i = mid;i<n;i++) R[i-mid] = A[i]; // creating right subarray

	MergeSort(L,mid);  // sorting the left subarray
	MergeSort(R,n-mid);  // sorting the right subarray
	Merge(A,L,mid,R,n-mid);  // Merging L and R into A as sorted list.
        free(L);
        free(R);
}

void fInsertion_Sort(int *pVetor, int TAM)
{
    int vAux;
    int vTemp;
    int vTroca;

    for (vAux=1; vAux < TAM; vAux++) // vAux começa na posição 1 do vetor e vai até a ultima posição;
    {
        vTemp = vAux; // vTemp recebe a posição que está passando no "for";

        while (pVetor[vTemp] < pVetor[vTemp-1]) // Enquanto o valor que está passando na posição "vTemp" for menor que a posição "vTemp" menos 1, ocorre a troca;
        { // Ocorre a troca;
            vTroca          = pVetor[vTemp];
            pVetor[vTemp]   = pVetor[vTemp-1];
            pVetor[vTemp-1] = vTroca;
            vTemp--; // vTemp decrementa 1;

            if (vTemp == 0) // Quando "vTemp" chegar na posição 0, primeira posição do vetor, o laço while para;
                break;
        }

    }
}

int main(){
	int n=0;
	int number;
	int *vector1;
	int *vector2;
	int i;
	int count=0;
	clock_t start;
	clock_t end;
	float seconds1;
	float seconds2;
	srand(time(NULL));
	
	while(count<MAX_VECTOR){
		count++;
		vector1=(int*)malloc(sizeof(int)*n);
		vector2=(int*)malloc(sizeof(int)*n);
		for(i=0;i<n;i++){
			number=rand()%n;
			vector1[i]=number;
			vector2[i]=number;
		}
		
		start=clock();
		fInsertion_Sort(vector1,n);
		end=clock();
		seconds1 = (float)(end - start) / CLOCKS_PER_SEC;
		
		start=clock();
		MergeSort(vector2,n);
		end=clock();
		seconds2 = (float)(end - start) / CLOCKS_PER_SEC;
		
		if(GNUPLOT){
			printf("%d %f %f\n",n,seconds1,seconds2);
		} else {
			printf("Insertion sort to vector size %d: %fs\n",n,seconds1);
			printf("Merge sort to vector size %d: %fs\n",n,seconds2);
		}
		
		n+=INCREMENT;
		free(vector1);
		free(vector2);
	}
	
	
	return 0;
}
