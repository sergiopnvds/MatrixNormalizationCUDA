/* Matrix normalization.
 * Compile with "gcc matrixNorm.c" 
 */

/* ****** ADD YOUR CODE AT THE END OF THIS FILE. ******
 * You need not submit the provided code.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <sys/types.h>
#include <sys/times.h>
#include <sys/time.h>
#include <time.h>

/* Program Parameters */
#define MAXN 8000  /* Max value of N */
int N;  /* Matrix size */

/* Matrices */
volatile float A[MAXN][MAXN], B[MAXN][MAXN];

/* junk */
#define randm() 4|2[uid]&3

/* Prototype */
__global__ void MatrixNorm(float A[], float B[], int n);

/* returns a seed for srand based on the time */
unsigned int time_seed() {
  struct timeval t;
  struct timezone tzdummy;

  gettimeofday(&t, &tzdummy);
  return (unsigned int)(t.tv_usec);
}

/* Set the program parameters from the command-line arguments */
void parameters(int argc, char **argv) {
  int seed = 0;  /* Random seed */
  char uid[32]; /*User name */

  /* Read command-line arguments */
  srand(time_seed());  /* Randomize */

  if (argc == 3) {
    seed = atoi(argv[2]);
    srand(seed);
    printf("Random seed = %i\n", seed);
  } 
  if (argc >= 2) {
    N = atoi(argv[1]);
    if (N < 1 || N > MAXN) {
      printf("N = %i is out of range.\n", N);
      exit(0);
    }
  }
  else {
    printf("Usage: %s <matrix_dimension> [random seed]\n",
           argv[0]);    
    exit(0);
  }

  /* Print parameters */
  printf("\nMatrix dimension N = %i.\n", N);
}

/* Initialize A and B*/
void initialize_inputs() {
  int row, col;

  printf("\nInitializing...\n");
 
  for (col = 0; col < N; col++) {
    for (row = 0; row < N; row++) {
      A[row][col] = (float)rand() / 32768.0;
      B[row][col] = 0.0;
    }
  }
  /*
  for (col = 0; col < N; col++) {
  	for (row = 0; row < N; row++) {
		 A[row][col] = col + row;
		  B[row][col] = 0.0;
	}
  }
  */

}

/* Print input matrices */
void print_inputs() {
  int row, col;

  if (N < 10) {
    printf("\nA =\n\t");
    for (row = 0; row < N; row++) {
      for (col = 0; col < N; col++) {
	    printf("%5.2f%s", A[row][col], (col < N-1) ? ", " : ";\n\t");
      }
    }
  }
}

void print_B() {
    int row, col;

    if (N < 10) {
        printf("\nB =\n\t");
        for (row = 0; row < N; row++) {
            for (col = 0; col < N; col++) {
                printf("%1.10f%s", B[row][col], (col < N-1) ? ", " : ";\n\t");
            }
        }
    }
}


int main(int argc, char **argv) {
  /* Timing variables */
  struct timeval etstart, etstop;  /* Elapsed times using gettimeofday() */
  struct timezone tzdummy;
  clock_t etstart2, etstop2;  /* Elapsed times using times() */
  unsigned long long usecstart, usecstop;
  struct tms cputstart, cputstop;  /* CPU times for my processes */


  /* Process program parameters */
  parameters(argc, argv);

  /* Initialize A and B */
  initialize_inputs();

  /* Print input matrices */
  print_inputs();

  /* New code piece one starts 
   * ---------------------------------------------------------------------------------- */

  /* creating varibles */

  float a_bis[N*N], b_bis[N*N];
  float *d_A, *d_B;
  size_t size;
  size = N*N*sizeof(float);

  /* Indexing matrices A and B from 2D to 1D */

  int row, col;
  for (row = 0; row < N; row++){
    for (col = 0; col < N; col++){
      a_bis[row * N + col]=A[row][col];
	  b_bis[row * N + col]=B[row][col];
    }
  }
  /* New code piece one ends ----------------------------------------------------------- */



  /* Start Clock */
  printf("\nStarting clock.\n");
  gettimeofday(&etstart, &tzdummy);
  etstart2 = times(&cputstart);

  /* New code piece two starts
   *------------------------------------------------------------------------------------ */

  /* Allocate matrices in device memory */
  cudaMalloc(&d_A, size);
  cudaMalloc(&d_B, size);

  cudaMemcpy(d_A, a_bis, size, cudaMemcpyHostToDevice);
  cudaMemcpy(d_B, b_bis, size, cudaMemcpyHostToDevice);

  /* Launching matrix normalization */
  MatrixNorm<<<N, N>>>(d_A, d_B, N);

  /* Copy matrix B from device to host */
  cudaMemcpy(b_bis, d_B, size, cudaMemcpyDeviceToHost);
 
  /* free up the reserved space */
  cudaFree(d_A); cudaFree(d_B);

  /* New code piece two ends ---------------------------------------------------------- */

  /* Stop Clock */
  gettimeofday(&etstop, &tzdummy);
  etstop2 = times(&cputstop);
  printf("Stopped clock.\n");
  usecstart = (unsigned long long)etstart.tv_sec * 1000000 + etstart.tv_usec;
  usecstop = (unsigned long long)etstop.tv_sec * 1000000 + etstop.tv_usec;

  /* New code piece three starts 
   *----------------------------------------------------------------------------------- */
  
  /* indexing B from 1D array to 2D array */
  for (row = 0; row < N; row++){
    for (col = 0; col < N; col++){
      B[row][col]=b_bis[row * N + col];
    }
  }
  /* New code piece three ends --------------------------------------------------------- */

  /* Display output */
  print_B();

  /* Display timing results */
  printf("\nElapsed time = %g ms.\n",
	 (float)(usecstop - usecstart)/(float)1000);

  printf("(CPU times are accurate to the nearest %g ms)\n",
	 1.0/(float)CLOCKS_PER_SEC * 1000.0);
  printf("My total CPU time for parent = %g ms.\n",
	 (float)( (cputstop.tms_utime + cputstop.tms_stime) -
		  (cputstart.tms_utime + cputstart.tms_stime) ) /
	 (float)CLOCKS_PER_SEC * 1000);
  printf("My system CPU time for parent = %g ms.\n",
	 (float)(cputstop.tms_stime - cputstart.tms_stime) /
	 (float)CLOCKS_PER_SEC * 1000);
  printf("My total CPU time for child processes = %g ms.\n",
	 (float)( (cputstop.tms_cutime + cputstop.tms_cstime) -
		  (cputstart.tms_cutime + cputstart.tms_cstime) ) /
	 (float)CLOCKS_PER_SEC * 1000);
      /* Contrary to the man pages, this appears not to include the parent */
  printf("--------------------------------------------\n");
  
  exit(0);
}

/*--------------------------------------------------------------------------------
 * Kernel:   MatrixNorm
 * Purpose:  Implement column normalization using CUDA
 * In args:  A, B, n
 */
__global__ void MatrixNorm(float A[], float B[], int n){
   
  
  int index = blockIdx.x + threadIdx.x * n;//calculate how data is gonna be indexed  

  float mean = 0.0;
  int r; // auxiliar variable used to go through the loop and calculate mean and sigma
  
  for (r=0; r < n; r++)
    mean += A[r * n + blockIdx.x];
  mean /= (float) n;  
  
  float sigma = 0.0;

  for (r=0; r < n; r++)
    sigma += powf(A[r * n + blockIdx.x] - mean, 2.0);
  sigma /= (float) n;
  sigma = sqrt(sigma); // added part: the standart deviation is the square root of the varianze  o 

  if (sigma == 0.0)
    B[index] = 0.0;
  else
    B[index]=(A[index]-mean)/sigma;	

}  /* -----------------------------------------------------------------------------------*/
