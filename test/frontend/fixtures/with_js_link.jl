### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ b0f2a778-885f-11ee-3d28-939ca4069ee8
begin
	import Pkg
	Pkg.activate(temp=true)
	Pkg.add([
		Pkg.PackageSpec(name="AbstractPlutoDingetjes", rev="Display.with_js_link")
		# Pkg.PackageSpec(path="/Users/fons/Documents/AbstractPlutoDingetjes.jl/")
		Pkg.PackageSpec(name="HypertextLiteral")
	])

	using AbstractPlutoDingetjes
	using HypertextLiteral
end

# ╔═╡ 37aacc7f-61fd-4c4b-b24d-42361d508e8d
@htl("""
<script>
const sqrt_from_julia = $(AbstractPlutoDingetjes.Display.with_js_link(sqrt))

// I can now call sqrt_from_julia like a JavaScript function. It returns a Promise:
const result = await sqrt_from_julia(9.0)
console.log(result)

</script>
""")

# ╔═╡ 30d7c350-f792-47e9-873a-01adf909bc84
md"""
If you change `String` to `AbstractString` here then you get some back logs:
"""

# ╔═╡ 75752f77-1e3f-4997-869b-8bee2c12a2cb
function cool(x::String)
	uppercase(x)
end

# ╔═╡ 3098e16a-4730-4564-a484-02a6b0278930
# function cool()
# end

# ╔═╡ 37fc039e-7a4d-4d2d-80f3-d409a9ee096d
# ╠═╡ disabled = true
#=╠═╡
let
	function f(x)
		cool(x)
	end
	@htl("""
	<script>
	const sqrt_from_julia = $(AbstractPlutoDingetjes.Display.with_js_link(f))
	
	let id = setInterval(async () => {
		console.log(await sqrt_from_julia("hello"))
	}, 50)
	
	invalidation.then(() => clearInterval(id))
	
	</script>
	""")
end
  ╠═╡ =#

# ╔═╡ 977c59f7-9f3a-40ae-981d-2a8a48e08349


# ╔═╡ b3186d7b-8fd7-4575-bccf-8e89ce611010
md"""
# Benchmark

We call the `next` function from JavaScript in a loop until `max` is reached, to calculate the time of each round trip.
"""

# ╔═╡ 82c7a083-c84d-4924-bad2-776d3cdad797
next(x) = x + 1;

# ╔═╡ e8abaff9-f629-47c6-8009-066bcdf67693
max = 250;

# ╔═╡ bf9861e0-be91-4041-aa61-8ac2ef6cb719
@htl("""
<div>
<p><input type="submit" value="start"></p>
<p>Current value: </p><input disabled type="number" value="0"></p>
<p>Past values: <input disabled style="width: 100%; font-size: .4em;"></p>
<p>Time per round trip: <input disabled ></p>
<script>
	const f_from_julia = $(AbstractPlutoDingetjes.Display.with_js_link(next))

	const div = currentScript.closest("div")
	const [submit,output,log,timer_log] = div.querySelectorAll("input")

	const max = $max

	submit.addEventListener("click", () => {
		output.value = 0
		log.value = "0"
		timer_log.value = "running..."
		let start_time = performance.now()
		
		let next = async () => {
			let val = await f_from_julia(output.valueAsNumber)
			
			output.valueAsNumber = val
			log.value += `,\${val}`
			if(output.valueAsNumber < max) {
				await next()
			} else {
				let end_time = performance.now()
				let dt = (end_time - start_time) / max
				timer_log.value = `\${_.round(dt, 4)} ms`
			}
		}

		next()
	})
	
</script>
</div>
""")

# ╔═╡ ebf79ee4-2590-4b5a-a957-213ed03a5921
md"""
# Concurrency
"""

# ╔═╡ 2417de50-e6e4-4c99-8836-ee8ff04d586a
1 + 1

# ╔═╡ 663e5a70-4d07-4d6a-8725-dc9a2b26b65d
md"""
# Tests
"""

# ╔═╡ 1d32fd55-9ca0-45c8-97f5-23cb29eaa8b3
md"""
Test a closure
"""

# ╔═╡ 5f3c590e-07f2-4dea-b6d1-e9d90f501fda
some_other_global = rand(100)

# ╔═╡ 3d836ff3-995e-4353-807e-bf2cd78920e2
some_global = 51:81

# ╔═╡ 2461d75e-81dc-4e00-99e3-bbc44000579f
AbstractPlutoDingetjes.Display.with_js_link(x -> x)

# ╔═╡ 12e64b86-3866-4e21-9af5-0e546452b4e1
function function_evaluator(f::Function, default=""; id=string(f))
	@htl("""
	<div class="function_evaluator" id=$(id)>
		<p>Input:<br>
		<input>&nbsp;<input type="submit"></p>
		
		<p>Output:<br>
		<textarea cols=40 rows=5></textarea>
	<script>
		let sqrt_with_julia = $(AbstractPlutoDingetjes.Display.with_js_link(f))
	
		let wrapper = currentScript.closest("div")
		wrapper.setAttribute("cellid", currentScript.closest("pluto-cell").id)
	
		let input = wrapper.querySelector("input")
		let submit = wrapper.querySelector("input[type='submit']")
		let output = wrapper.querySelector("textarea")
	
		submit.addEventListener("click", async () => {
			let result = await sqrt_with_julia(input.value)
			output.innerText = result
		})

		input.value = $(AbstractPlutoDingetjes.Display.published_to_js(default))
		submit.click()
	</script>
	
	</div>
	""")
end

# ╔═╡ 4b80dda0-74b6-4a0e-a50e-61c5380111a4
function_evaluator(900; id="sqrt") do input
	num = parse(Float64, input)
	sqrt(num)
end

# ╔═╡ a399cb12-39d4-43c0-a0a7-05cb683dffbd
function_evaluator("c1"; id="c1") do input
	# @info "start"
	sleep(3)
	# @warn "end"
	uppercase(input)
	
end

# ╔═╡ 2bff3975-5918-40fe-9761-eb7b47f16df2
function_evaluator("c2"; id="c2") do input
	# @info "start"
	sleep(3)
	# @warn "end"
	uppercase(input)
end

# ╔═╡ 2b5cc4b1-ca57-4cb6-a42a-dcb331ed2c26
let
	thing = function_evaluator("1") do str
		some_other_global[1:parse(Int,str)]
	end
	if false
		fff() = 123
	end
	thing
end

# ╔═╡ 85e9daf1-d8e3-4fc0-8acd-10d863e724d0
let
	x = rand(100)
	function_evaluator("1") do str
		x[parse(Int,str)]
	end
end

# ╔═╡ abb24301-357c-40f0-832e-86f26404d3d9
function_evaluator("THIS IN LOWERCASE") do input
	"you should see $(lowercase(input))"
end

# ╔═╡ 33a2293c-6202-47ca-80d1-4a9e261cae7f
function_evaluator(4; id="logs1") do input
	@info "you should see this log $(input)"
	println("(not currently supported) you should see this print $(input)")
	
	rand(parse(Int, input))
end

# ╔═╡ 480aea45-da00-4e89-b43a-38e4d1827ec2
function_evaluator("coOL") do input
	@warn("You should see the following error:")
	
	error("You should see this error $(uppercase(input))")
end

# ╔═╡ b310dd30-dddd-4b75-81d2-aaf35c9dd1d3
function_evaluator(4) do input
	@warn("You should see the assertpackable fail after this log")

	:(@heyyy cant msgpack me)
end

# ╔═╡ 58999fba-6631-4482-a811-12bf2412d65e
function_evaluator(4; id="globals") do input
	some_global[parse(Int, input)]
end

# ╔═╡ 9e5c0f8d-6ac1-4aee-a00d-938f17eec146
md"""
You should be able to use `with_js_link` multiple times within one cell, and they should work independently of eachother:
"""

# ╔═╡ 306d03da-cd50-4b0c-a5dd-7ec1a278cde1
@htl("""
<div style="display: flex; flex-direction: row;">
	$(function_evaluator(uppercase, "Παναγιώτης"))
	$(function_evaluator(lowercase, "Παναγιώτης"))
</div>
""")

# ╔═╡ 2cf033a7-bcd7-434d-9faf-ea761897fb64
md"""
You should be able to set up a `with_js_link` in one cell, and use it in another. This example is a bit trivial though...
"""

# ╔═╡ 40031867-ee3c-4aa9-884f-b76b5a9c4dec
fe = function_evaluator(length, "Alberto")

# ╔═╡ 7f6ada79-8e3b-40b7-b477-ce05ae79a668
fe

# ╔═╡ f344c4cb-8226-4145-ab92-a37542f697dd
md"""
You should see a warning message when `with_js_link` is not used inside an HTML renderer that supports it:
"""

# ╔═╡ 8bbd32f8-56f7-4f29-aea8-6906416f6cfd
let
	html_repr = repr(MIME"text/html"(), fe)
	HTML(html_repr)
end

# ╔═╡ Cell order:
# ╠═b0f2a778-885f-11ee-3d28-939ca4069ee8
# ╠═4b80dda0-74b6-4a0e-a50e-61c5380111a4
# ╠═37aacc7f-61fd-4c4b-b24d-42361d508e8d
# ╟─30d7c350-f792-47e9-873a-01adf909bc84
# ╠═75752f77-1e3f-4997-869b-8bee2c12a2cb
# ╠═3098e16a-4730-4564-a484-02a6b0278930
# ╠═37fc039e-7a4d-4d2d-80f3-d409a9ee096d
# ╠═977c59f7-9f3a-40ae-981d-2a8a48e08349
# ╟─b3186d7b-8fd7-4575-bccf-8e89ce611010
# ╠═82c7a083-c84d-4924-bad2-776d3cdad797
# ╠═e8abaff9-f629-47c6-8009-066bcdf67693
# ╟─bf9861e0-be91-4041-aa61-8ac2ef6cb719
# ╟─ebf79ee4-2590-4b5a-a957-213ed03a5921
# ╠═a399cb12-39d4-43c0-a0a7-05cb683dffbd
# ╠═2bff3975-5918-40fe-9761-eb7b47f16df2
# ╠═2417de50-e6e4-4c99-8836-ee8ff04d586a
# ╟─663e5a70-4d07-4d6a-8725-dc9a2b26b65d
# ╟─1d32fd55-9ca0-45c8-97f5-23cb29eaa8b3
# ╠═5f3c590e-07f2-4dea-b6d1-e9d90f501fda
# ╠═2b5cc4b1-ca57-4cb6-a42a-dcb331ed2c26
# ╠═85e9daf1-d8e3-4fc0-8acd-10d863e724d0
# ╠═abb24301-357c-40f0-832e-86f26404d3d9
# ╠═33a2293c-6202-47ca-80d1-4a9e261cae7f
# ╠═480aea45-da00-4e89-b43a-38e4d1827ec2
# ╠═b310dd30-dddd-4b75-81d2-aaf35c9dd1d3
# ╠═3d836ff3-995e-4353-807e-bf2cd78920e2
# ╠═58999fba-6631-4482-a811-12bf2412d65e
# ╠═2461d75e-81dc-4e00-99e3-bbc44000579f
# ╠═12e64b86-3866-4e21-9af5-0e546452b4e1
# ╟─9e5c0f8d-6ac1-4aee-a00d-938f17eec146
# ╠═306d03da-cd50-4b0c-a5dd-7ec1a278cde1
# ╟─2cf033a7-bcd7-434d-9faf-ea761897fb64
# ╠═40031867-ee3c-4aa9-884f-b76b5a9c4dec
# ╠═7f6ada79-8e3b-40b7-b477-ce05ae79a668
# ╟─f344c4cb-8226-4145-ab92-a37542f697dd
# ╠═8bbd32f8-56f7-4f29-aea8-6906416f6cfd
