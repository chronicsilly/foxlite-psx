Any feedback is appreciated! And any contribution to FoxLite is a 🐾step to detrone Unreal Engine! ... maybe not but we can try!

If you have any feature you'd like to be added to FoxLite, feel free to discuss it with us!

## Issue reporting guidelines
- See if there isn't an already open/closed issue, duplicates are kind of a bummer to go trough.
- Create a minimal project reproducing the issue and attach screenshots or video of it if necessary.
- Describe the exact steps that cause the problem, and what should be expected to happen.
- Always provide logs if any!

And be civilized y'all, thank you.

## Pull Request guidelines
*TL;DR:* Just make sure your code runs in all platforms, including V-Slice, without much performance impact and without much AI
- Make sure to thoroughly test your scripts in both V-Slice and haxelib, this is to make sure FoxLite works in both targets.
- If you're adding/changing graphics-related code, make sure it works in the following targets: `linux`, `windows`, `android`, `html5` in an Intel/NVIDIA GPU, AMD GPU and Mobile GPU. This is because GPU manufacturers have different shader compilers, so what works in one may not work in another.
- Do not use AI to code for you. You can use it as means of research and explaining what the code does, but it's always best to experiment and ask other devs about it.
> Due to the nature of the project, performance is critical if running in a softcoded environment such as HScript, things that may work for haxe will either run poorly or not work at all, so it's better if you test things for yourself rather than asking AI to fix it for you.

## License

FoxLite is free, open source software licensed under the [MIT License](https://github.com/dwdvIl/foxlite/blob/master/LICENSE_MIT)
