/////////////////////////////////////////////////
//Varational Quantum Oscillator V.1.2
//Copyright Spencer Topel & Parker Kuklinski 2022
//Physical Synthesis / Zapata Computing
/////////////////////////////////////////////////



//This code is necessary to run this program on the Virginia Tech Cube System. 
(
s.options.device = "AggregateFocusRite+Dante";
s.options.memSize = 2 ** 20;
s.options.numInputBusChannels = 0;
s.options.numOutputBusChannels = 256;
s.options.numPrivateAudioBusChannels = 4096;
s.options.sampleRate = 48000;
s.options.maxSynthDefs = 8192;
s.options.numBuffers = 8192;
s.options.maxNodes = 8192;
s.options.numWireBufs=128;
s.latency = 0.2;
s.boot;
)

//Important! This gives you GUI control of the system (e.g. volume)
s.makeGui;


(
//f is the tensor product operator
f = { |a, b|
	a.collect { |x|
		x.collect { |y| b * y }.reduce('+++')
	}.reduce('++')
};

//m is the matrix multiplication operator
m = { |self, other|

	var size = self.size;
	var out = Array.fill(size, { Array.new(size) });
	var transposed = other.flop;

	self.do { | row, i |
		size.do { | j |
			var c = transposed[j];
			c !? { out[i].add(sum(row * c)) }
		}
	};

	out
}
)

(
SynthDef("vqo", {
    arg outArray=0, realVal=1.0, qunantOscIndexed=13.0, frequencyMultiple=1.0, indexVal=13.0, out=0, amplitude=0.1;
	var quantOsc;
	quantOsc={SinOsc.kr(realVal)};
	qunantOscIndexed = quantOsc * indexVal;
    outArray = [SinOsc.ar([41.2222 * frequencyMultiple], qunantOscIndexed, amplitude)];
    Out.ar(out, outArray);
}).add;
)

(
//define variables
var x1, x2, x3, x4, x5, x6, t1, t2, t3, t4, t5, h, h1, h2, h3, v, m1, m2, m3, p1, p2, realVal, sizeCheck;


//define a random unit vector. we should be careful to define this vector first so that it does not update with random parameters and is instead constant throughout the simulation
v = { 1.0.sum3rand }.dup(64);
v = v/sqrt(abs(v*v).sum);

//create individual rotation gates, essentially applying a rotation gate to each qubit. these rotations will become parameterized for our control
x1 = [[1,0],[0,exp(Complex(0,10000.rand))]];
x2 = [[1,0],[0,exp(Complex(0,10000.rand))]];
x3 = [[1,0],[0,exp(Complex(0,10000.rand))]];
x4 = [[1,0],[0,exp(Complex(0,10000.rand))]];
x5 = [[1,0],[0,exp(Complex(0,10000.rand))]];
x6 = [[1,0],[0,exp(Complex(0,10000.rand))]];


//tensor rotation gates together for the full unitary representation
t1 = f.value(x1,x2);
t2 = f.value(t1,x3);
t3 = f.value(t2,x4);
t4 = f.value(t3,x5);
t5 = f.value(t4,x6);

//create a hadamard tensor matrix, representing applying a hadamard operator to each individual qubit
h = [[1,1],[1,-1]]/sqrt(2);
h1=f.value(h,h);
h2=f.value(h1,h1);
h3=f.value(h2,h1);


//multiply the hadamard tensor with the rotation tensor, then multiply that product by the unit vector
p1 = m.value(h3,t5);
p2 = m.value(p1,v.flop);
realVal =p2.asFloat;


//the result is that we have an audio representation of a parameterized quantum circuit; a rotation tensor composed with a hadamard gate to mix states up. the next steps could be to use more complicated entangling operators in place of the hadamard, or to have a more complicated ansatz such that the parameters have even more complex behaviors

64.do({ arg item;
	d = Synth("vqo",["out",item, "realVal", realVal[item], "frequencyMultiple", [item], "amplitude", 0.03])});
)