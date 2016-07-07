require 'rubygems'
require 'rmagick'

img = Magick::Image::read("./style.jpg")[0]
img_out = Magick::Image::read("./in.jpg")[0]

$alpha = 0.7
$maxcv = 65536

class Nn
    def initialize(xl, yl)
	@xl = xl
	@yl = yl
	puts "Nn size: #{@xl}, #{@yl}"
	@layers = 2
	@nn = Array.new()
	(0..@layers-1).each do |l|
		@nn << Array.new
		nnlayer = @nn[ l ]
		prng1 = Random.new(1234)
		(0..@xl * @yl - 1).each do |i| 
			nnlayer << Array.new
			(0..2).each { |u| nnlayer[i] << prng1.rand }
		end
	end
    end

    def learn_f(n, signal, c)
#	r = n + c * 1.0 / (1.0 + Math::E ** ( 1.0 - 4.0 * (signal) / 65536.0 ) )
#	print r, " ", n, " ", signal, "\n"
#	return r
#	return (1.0 / (1.0 + Math::E ** ( 1.0 * signal / $maxcv ) ))
	return n * (1.0 - $alpha) + ($alpha) * (1.0 / (1.0 + Math::E ** ( 1.0 - 4.0 * signal / $maxcv ) ))
    end

    def add2nn(img)
	@nn.each do |nnlayer|
		i = 0
			img.map do |p|
				ca = [p.red, p.green, p.blue]
				len = nnlayer.length
				(0..2).each do |c|
					nnlayer[i][c] = learn_f(nnlayer[i][c], ca[c], 1.0 / len)
					x = 1
					if (i > x && i < len - x)
						(-x..x).each do |po|
							nnlayer[i+po][c] = learn_f(nnlayer[i+po][c], ca[c], 1.0 / len)
						end
					end
				end
				i += 1
			end
	end
	(0..2).each do |c|
		max = 0.0
		@nn.each do |nnl|
			nnl.each do |v|
				if max < v[c]
					max = v[c]
				end
			end
			nnl.each do |v|
				v[c] = (max - v[c])
			end
		end
	end
    end

    def l(img)
	(0..(img.columns/@xl)).each do |i|
	    (0..(img.rows/@yl)).each do |u|
		if (i * @xl + @yl > img.columns) || (u * @xl + @yl > img.rows)
		    next
		end
		subimage = img.get_pixels(i * @xl, u * @yl, @xl, @yl)
		add2nn(subimage)
	    end
	end
    end

    def impl(in_img_out)
	img_out = in_img_out.clone
	@nn.each do |nnl|
		(0..img_out.columns).each do |i|
		    (0..img_out.rows).each do |u|
			p = img_out.pixel_color(i, u)
			ind = (i % @xl) * @yl + u % @yl
			p.red = nnl[ ind ][0] * p.red #$alpha + (1 - $alpha) * p.red
			p.green = nnl[ ind ][1] * p.green #$alpha + (1 - $alpha) * p.green
			p.blue = nnl[ ind ][2] * p.blue #$alpha + (1 - $alpha) * p.blue
			img_out.pixel_color(i, u, p)
		    end
		end
	end
	return img_out
    end

end

def sigmoid(v)
    r = v #1.0 / (1.0 + Math::E ** (0.3 - 1.0 * v))
end

def color_tuner(img_out)
	m = [0,0,0]
	n = m.clone
	(0..img_out.columns).each do |i|
	    (0..img_out.rows).each do |u|
		pr = img_out.pixel_color(i, u)
		m[0] = pr.red if pr.red > m[0]
		m[1] = pr.green if pr.green > m[1]
		m[2] = pr.blue if pr.blue > m[2]
	    end
	end
	(0..img_out.columns).each do |i|
	    (0..img_out.rows).each do |u|
		p = img_out.pixel_color(i,u)
		p.red = $maxcv * sigmoid((1.0 * p.red / m[0]))
		p.green = $maxcv * sigmoid((1.0 * p.green / m[0]))
		p.blue = $maxcv * sigmoid((1.0 * p.blue / m[0]))
		img_out.pixel_color(i,u,p)
		n[0] = p.red if n[0] < p.red
		n[1] = p.green if n[1] < p.green
		n[2] = p.blue if n[2] < p.blue
	    end
	end
	puts n.join(" ")
	img_out
end

nn = []

nn << Nn.new(900, 900)
nn << Nn.new(100, 100)

puts "This image is #{img.columns} x #{img.rows} pixels"

#subimage = img.splice(90, 90, img.columns, img.rows)

(0..1).each do |count|
    nn.each do |n| 
	n.l(img)
#	n.l(subimage)
    end
end

puts "NN Trained"
(0..0).each do |count|
    nn.each do |n|
	img_out = n.impl(img_out)
    end
end

img_out = color_tuner(img_out)

img_out.write("out.jpg")
