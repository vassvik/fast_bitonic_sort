import numpy 
import glob
import matplotlib.pyplot as plt 

def find_best_fit(N, r):
	R = 1
	C = 1
	while R*C < N:
		if C/R < r: C += 1
		else:       R += 1
	return (R, C)


files = [
	"series_Init.txt",
	"series_Sort.txt",
	"series_Verify.txt",
	"series_Sort _1024.txt",
	"series_Sort _2048.txt",
	"series_Sort _4096.txt",
	"series_Sort _8192.txt",
	"series_Sort _16384.txt",
	"series_Sort _32768_1.txt",
	"series_Sort _32768_2.txt",
	"series_Sort _65536_1.txt",
	"series_Sort _65536_2.txt",
	"series_Sort _131072_1.txt",
	"series_Sort _131072_2.txt",
	"series_Sort _262144_1.txt",
	"series_Sort _262144_2.txt",
]

R, C = 4, 4
fig1, axes1 = plt.subplots(R, C, figsize=(16,9))
fig1.subplots_adjust(hspace=0.35, wspace=0.2, top=0.97, bottom=0.04, left=0.03, right=0.97)

for i in range(len(files)):
	filename = files[i]
	try:
		x = i % C
		y = i // C
		name = filename[len("series_"):len(filename)-len(".txt")]

		timestep, time = numpy.loadtxt(files[i], unpack=True)
		
		if len(files) == 1: ax1 = axes1
		elif R == 1: ax1 = axes1[x]
		else:      ax1 = axes1[y, x]

		ax1.plot(timestep, time*1.0e6, '.', label=name, alpha=0.1)
		ax1.set_ylabel("execution time (µs)")
		ax1.set_xlabel("simulation time (step)")
		ax1.set_title(name)
	except:
		print("WHAT", filename)

fig3, ax3 = plt.subplots(1, 1, figsize=(16,9))

for i in range(len(files)):
	filename = files[i]
	try:
		name = filename[len("series_"):len(filename)-len(".txt")]

		timestep, time = numpy.loadtxt(files[i], unpack=True)
		
		ax3.plot(timestep, time*1.0e6, '.', label=name, alpha=0.5)
		ax3.set_ylabel("execution time (µs)")
		ax3.set_xlabel("simulation time (step)")
	except:
		print("WHAT 2", filename)

ax3.grid()
ax3.legend()

plt.show()