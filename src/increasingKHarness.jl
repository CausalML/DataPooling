###
# Test using simulated Rossman Data
#
# For increasing K, simulate datasets and performance 
# of various methods SAA, Alpha LOO, and Alpha OR
###
using Distributions
include("../src/JS_SAA_main.jl")

#supp_full, ps_full are d x K matrices with true info per problem
#adds new subproblems in order appear in files
#s is the service level, N is the average amount of data per problem
function convInKtest(numRuns, K_grid, supp_full, ps_full, outPath, N, s; 
						usePoisson=true, seed=8675309)
	const Kmax = maximum(K_grid)
	@assert Kmax <= size(supp_full, 2) "K_grid exceeds available subproblems"
	@assert size(supp_full) == size(ps_full) "supp_full and ps_full have incompatible dimensions"

	const d = size(supp_full, 1)

	#For safety, trim inputs to size Kmax
	supp_full = view(supp_full, 1:d, 1:Kmax)
	ps_full = view(ps_full, 1:d, 1:Kmax)

	p0 = ones(d)/d
	alpha_grid = linspace(0, 180, 120)

	#set up output file
	f = open("$(outPath).csv", "w")
	writecsv(f, ["Run" "K" "d" "Method" "TruePerf" "time" "alpha"])

	#generate all Kmax subproblems upfront and store in memory
	cs_full, xs_full = JS.genNewsvendorsDiffSupp(supp_full, s, Kmax)
	lam_full   = ones(Kmax)

	for iRun = 1:numRuns
		#simulate data for the run
		Nhats_full = usePoisson ? rand(Poisson(N), Kmax) : ones(Kmax) * N
		mhats_full = JS.sim_path(ps_full, Nhats_full)

		for K in K_grid
			#Take views on evrything for simplicity
			lams = view(lam_full, 1:K)
			supp = view(supp_full, 1:d, 1:K)
			ps = view(ps_full, 1:d, 1:K)
			Nhats = view(Nhats_full, 1:K)
			mhats = view(mhats_full, 1:d, 1:K)
			cs = view(cs_full, 1:d, 1:K)
			xs = view(xs_full, 1:K)

			#for data-driven shrinkage anchor
			phat_avg = vec(mean(mhats ./ Nhats', 2))

			#Compute the full-info value once for reference
			if iRun == 1
				tic()
				full_info = JS.zstar(xs, cs, ps, lams)
				t = toc()
				println(full_info)
				writecsv(f, [1 K d "FullInfo" full_info t 0.])
			end

			#SAA
			tic()
			perf_SAA = JS.zbar(xs, cs, p0, 0., mhats, ps, lams)
			t = toc()
			writecsv(f, [iRun K d "SAA" perf_SAA t 0.0])

			#Gen the Oracle cost with 1/d anchor
			tic()
			alphaOR, min_indx, or_alpha_curve = JS.oracle_alpha(xs, cs, mhats, ps, lams, p0, alpha_grid)
			t = toc()
			writecsv(f, [iRun K d "Oracle" or_alpha_curve[min_indx] t alphaOR])

			#Gen the LOO cost with 1/d anchor
			tic()
			alphaLOO, min_indx, looUnsc_curve = JS.loo_alpha(xs, cs, mhats, p0, alpha_grid)
			t = toc()
			writecsv(f, [iRun K d "LOO_unif" or_alpha_curve[min_indx] t alphaLOO])

			#Gen the Oracle cost with GM Anchor
			tic()
			alphaOR_GM, min_indx, or_alpha_curve_GM = JS.oracle_alpha(xs, cs, mhats, ps, lams, phat_avg, alpha_grid)
			t = toc()
			writecsv(f, [iRun K d "OraclePhat" or_alpha_curve_GM[min_indx] t alphaOR_GM])

			#Gen the LOO cost with the GM Anchor
			tic()
			alphaLOO, min_indx, looUnsc_curve = JS.loo_alpha(xs, cs, mhats, phat_avg, alpha_grid)
			t = toc()
			writecsv(f, [iRun K d "LOO_avg" or_alpha_curve_GM[min_indx] t alphaLOO])

		end  #end K Loop
		flush(f)
	end #end run loop 
	close(f)
	"$(outPath).csv"
end #end function 
