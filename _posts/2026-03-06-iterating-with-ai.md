---
layout: post
title: "Iterating with AI: How a PDF compression feature evolved through 9 revisions"
date: 2026-03-06
categories: ai
excerpt: "A real-world example of building a feature with Claude Code. The AI produced working code on the first attempt, but it took 9 rounds of feedback to shape it into something I was happy with."
---

## The Problem

We had a Rails app that uploads scanned PDF documents through an API. Some documents exceeded the 10MB size limit,
causing an error.

The solution: automatically compress oversized PDFs and retry, reducing by 10% each attempt, up to 3 times.

This Blog Post shows my iterations on the problem with Claude and why I don't really understand how can people possibly
think, in March 2026, that coding is dead.
I love being assisted by AI in my daily work, but somehow the quality is not there yet.

But I'm sure I just need yet another prompt, or yet a better CLAUDE.md file.

What follows is a real-world example of iterating with Claude Code to build a feature. The AI produced working code on
the first attempt, but it took 10+ rounds of feedback to shape it into something I was happy with. Every version of the
code is included - simplified - to show how the design evolved.

---

## Version 1: Introducing the PdfCompressor

The first version put all logic in `PdfCompressor` — the retry loop, error detection, and compression. It used
Ghostscript with DPI downsampling.

This is the original code:

```ruby
# `app/models/ibm_document.rb`

def self.create(pdf_pdf_file_bytes)
  api_client.documents.create(pdf_pdf_file_bytes)
end
```

And here's the first - working - solution from Claude Code

```ruby
# `app/models/ibm_document.rb` — v1 (create method)

def self.create(pdf_file_bytes)
  PdfCompressor.with_compression_retry(pdf_file_bytes) do |bytes|
    api_client.documents.create(bytes)
  end
end
```

```ruby
# `app/services/pdf_compressor.rb` — v1

class PdfCompressor
  MAX_RETRIES = 3
  SCALE_FACTOR = 0.9
  EXCEEDED_MESSAGE_SIZE_ERROR = "Access Denied due to exceeded message size"

  def self.with_compression_retry(pdf_file_bytes, &block)
    new(pdf_file_bytes).with_compression_retry(&block)
  end

  def initialize(pdf_file_bytes)
    @pdf_file_bytes = pdf_file_bytes
  end

  def with_compression_retry
    current_bytes = @pdf_file_bytes
    retries = 0

    loop do
      response = yield(current_bytes)
      return response if response.success?

      break response unless exceeded_message_size?(response)
      break response if retries >= MAX_RETRIES

      retries += 1
      current_bytes = compress(current_bytes, retries)
    end
  end

  private

  def exceeded_message_size?(response)
    response.data.to_s.include?(EXCEEDED_MESSAGE_SIZE_ERROR)
  end

  def compress(pdf_file_bytes, attempt)
    scale = SCALE_FACTOR ** attempt
    dpi = (300 * scale).round

    Tempfile.create(["input", ".pdf"]) do |input|
      Tempfile.create(["output", ".pdf"]) do |output|
        input.binmode
        input.write(pdf_file_bytes)
        input.flush

        system(
          "gs", "-sDEVICE=pdfwrite", "-dCompatibilityLevel=1.4",
          "-dColorImageResolution=#{dpi}", "-dGrayImageResolution=#{dpi}",
          "-dMonoImageResolution=#{dpi}",
          "-dDownsampleColorImages=true", "-dDownsampleGrayImages=true", "-dDownsampleMonoImages=true",
          "-dNOPAUSE", "-dBATCH", "-dQUIET",
          "-sOutputFile=#{output.path}", input.path,
          exception: true
        )

        File.binread(output.path)
      end
    end
  end
end
```

Although the first version worked, the code felt just wrong.

My main concern, at this stage, was the separation of concern: I did not like at all that the new PdfCompressor did way
more than just compressing the PDF file.

In particular, it **knew** about the specific error message or the fact that there's a response object: that has nothing
to do with the task of compressing a PDF.

So here comes a second version.

---

## Version 2: Separation of concerns — compress only

**My feedback:** *"The pdf_compressor is implementing a nice loop and retry mechanism, but it should just take care of
the compression and not know anything about the error or why it has to be compressed."*

Moved the retry logic to `IbmDocument`, made `PdfCompressor` only know about compression.

```ruby
# `app/models/ibm_document.rb` — v2 (create method)

EXCEEDED_MESSAGE_SIZE_ERROR = "Access Denied due to exceeded message size"
MAX_COMPRESSION_RETRIES = 3

def self.create(pdf_file_bytes)
  current_bytes = pdf_file_bytes

  MAX_COMPRESSION_RETRIES.times do |attempt|
    response = api_client.documents.create(current_bytes)
    return response if response.success?
    break unless exceeded_message_size?(response)

    current_bytes = PdfCompressor.compress(current_bytes, attempt: attempt + 1)
  end

  response = api_client.documents.create(current_bytes)
  response
end

def self.exceeded_message_size?(response)
  response.data.to_s.include?(EXCEEDED_MESSAGE_SIZE_ERROR)
end
```

```ruby
# `app/services/pdf_compressor.rb` — v2

class PdfCompressor
  SCALE_FACTOR = 0.9

  def self.compress(pdf_file_bytes, attempt:)
    new(pdf_file_bytes, attempt: attempt).compress
  end

  def initialize(pdf_file_bytes, attempt:)
    @pdf_file_bytes = pdf_file_bytes
    @attempt = attempt
  end

  def compress
    dpi = (300 * (SCALE_FACTOR ** @attempt)).round

    run_ghostscript(input.path, output.path, dpi)
  end

  private

  def run_ghostscript(input_path, output_path, dpi)
    system(
      "gs", "-sDEVICE=pdfwrite", "-dCompatibilityLevel=1.4",
      "-dColorImageResolution=#{dpi}", "-dGrayImageResolution=#{dpi}", "-dMonoImageResolution=#{dpi}",
      "-dDownsampleColorImages=true", "-dDownsampleGrayImages=true", "-dDownsampleMonoImages=true",
      "-dNOPAUSE", "-dBATCH", "-dQUIET",
      "-sOutputFile=#{output_path}", input_path,
      exception: true
    )
  end
end
```

We now got a clear separation of concern, but the code became unreadable: it's a huge mess and it's also broken.

Claude failed completely at keeping concerns separated while extracting the right logic into the right place.

A couple of concrete notes:

* `IbmDocument` is now responsible for looping and compressing further the document. This is exactly what the
  PdfCompressor should take care of! We had it in version 1 with the method `with_compression_retry` and now it's lost.
  I want the cake, and I want to eat it too!
* The `IbmDocument` is now looping three times, but if the API errors for a different reason and breaks the loop, it
  performs another call.
* The `PDfCompressor#compress` method now takes an `attempt` argument. This is just so wrong! This method should just
  know about how much it should compress, not be aware of any loop strategy.
* I like that it extracted the ghostscript call

Let's try to fix this in the next version.

---

## Version 3: Loop back in PdfCompressor, percentage-based compress

**My feedback:** *"I liked that the PdfCompressor was also offering a method to retry a certain number of times, so
the 'looping' logic stays in there, while the implementation details and continue or break in the caller. I think the
compress method should take pdf_file_bytes and a percentage of compression, not 'attempts', the attempts logic stays in
the loop."*

I brought the loop back as `progressively_compress` (I decided the name!!) and made `compress` take a percentage instead
of attempt number.

```ruby
# `app/models/ibm_document.rb` — v3 (create method)

response = api_client.documents.create(current_bytes)

if !response.success? && exceeded_message_size?(response)
  PdfCompressor.progressively_compress(pdf_file_bytes, max_retries: MAX_COMPRESSION_RETRIES) do |compressed_bytes|
    response = response = api_client.documents.create(compressed_bytes)
    break if response.success?
    break unless exceeded_message_size?(response)
  end
end
response
```

```ruby
# `app/services/pdf_compressor.rb` — v3

class PdfCompressor
  SCALE_FACTOR = 0.9

  def self.compress(pdf_bytes, percentage:)
    new(pdf_bytes).compress(percentage: percentage)
  end

  def self.progressively_compress(pdf_bytes, max_retries: 3, step: 10, &)
    new(pdf_bytes).progressively_compress(max_retries: max_retries, step: step, &)
  end

  def initialize(pdf_bytes)
    @pdf_bytes = pdf_bytes
  end

  def compress(percentage:)
    dpi = (300.0 * percentage / 100).round

    run_ghostscript(input.path, output.path, dpi)
  end

  def progressively_compress(max_retries: 3, step: 10)
    percentage = 100

    max_retries.times do
      percentage -= step
      @pdf_bytes = compress(percentage: percentage)
      yield(@pdf_bytes)
    end
  end

  private

  def run_ghostscript(input_path, output_path, dpi)
    # ...
  end
end
```

I feel like we are slowly getting there: my urge of taking over is big now, but I wanted to see how many prompts it
would take to get it right. Consider that at this point I already did at least two manual changes:

* Move constants definition above the methods where they were used
* Rename `with_compression_retries` into `progressively_compress`

I now wanted to get rid of the instance method of PdfCompressor and just stay with class level methods. It made no sense
to have both.

Also, I don't want named parameters when they are not optional, so the `percentage:` named parameter should be changed.

---

## Version 4: Class-only methods

**My feedback:** *"The PdfCompressor can have only class level methods. I don't see a need for having also instance
methods. Also, the compress method takes a percentage parameter. Don't use a named parameter. It's not optional."*

Removed the instance methods and constructor. Everything is a class method now.

```ruby
# `app/services/pdf_compressor.rb` — v4

class PdfCompressor
  def self.compress(pdf_bytes, percentage)
    dpi = (300.0 * percentage / 100).round

    run_ghostscript(input.path, output.path, dpi)
  end

  def self.progressively_compress(pdf_bytes, max_retries: 3, step: 10)
    percentage = 100

    max_retries.times do
      percentage -= step
      pdf_bytes = compress(pdf_bytes, percentage: percentage)
      yield(pdf_bytes)
    end
  end

  def self.run_ghostscript(input_path, output_path, dpi)
    # ...
  end
end
```

As a Software Engineer, I think our job is to call things by their name. That's why `step` in a `progressively_compress`
method makes no sense. Let's call it by its name: `progressive_compression_percentage`.

---

## Version 5: Renamed step to compression_percentage

**My feedback:** *"I don't like the variable 'step', this is the progressive_compression_percentage."*

Simple rename of the parameter.

```ruby
# `app/services/pdf_compressor.rb` — v5 (progressively_compress)

def self.progressively_compress(pdf_bytes, max_retries: 3, compression_percentage: 10)
  percentage = 100

  max_retries.times do
    percentage -= compression_percentage
    pdf_bytes = compress(pdf_bytes, percentage)
    yield(pdf_bytes)
  end
end
```

Let's now focus on the `IbmDocument#create` method:

```ruby

response = api_client.documents.create(current_bytes)

if !response.success? && exceeded_message_size?(response)
  PdfCompressor.progressively_compress(pdf_file_bytes, max_retries: MAX_COMPRESSION_RETRIES) do |compressed_bytes|
    response = response = api_client.documents.create(compressed_bytes)
    break if response.success?
    break unless exceeded_message_size?(response)
  end
end
response
```

Using the `PdfCompressor` this way is just ugly. You need to perform a first call and then, if it fails, start the
compression.
That's not what I had in mind: I want the PdfCompressor to take care of everything in the loop.

---

## Version 6: First iteration yields original bytes

**My feedback:** *"I don't like that the caller needs to execute the call before the block. Adapt the compressor so it
does not immediately decrease in the first loop iteration, so it's easier for the caller."*

The first yield now returns the original bytes, so the caller doesn't need a separate call before the block.

```ruby
# `app/models/ibm_document.rb` — v6 (create method, just the loop)

response = nil

PdfCompressor.progressively_compress(pdf_file_bytes, max_retries: MAX_COMPRESSION_RETRIES) do |bytes|
  response = submit(bytes)
  break if response.success?
  break unless exceeded_message_size?(response)
end
response
```

```ruby
# `app/services/pdf_compressor.rb` — v6 (progressively_compress)

def self.progressively_compress(pdf_bytes, max_retries: 3, compression_percentage: 10)
  percentage = 100

  (max_retries + 1).times do
    yield(pdf_bytes)
    percentage -= compression_percentage
    pdf_bytes = compress(pdf_bytes, percentage)
  end
end
```

And here I realise that talking about `retries` has been misleading for Claude all this time.
I said "3 retries", but what I meant was "3 attempts". That's why the loop looks so ugly.

---

## Version 7: Attempts instead of retries

**My feedback:** *"I want 'attempts' not retries, so if I say 3, it tries 3
times, not 4."*

Changed the semantics: `attempts: 3` means exactly 3 yields, not 3 retries + 1 initial.

```ruby
# `app/models/ibm_document.rb` — v7

MAX_COMPRESSION_ATTEMPTS = 3
PdfCompressor.progressively_compress(pdf_file_bytes, attempts: MAX_COMPRESSION_ATTEMPTS) do |bytes|
  # ...
end
```

```ruby
# `app/services/pdf_compressor.rb` — v7 (progressively_compress)

def self.compress(pdf_bytes, percentage)
  return pdf_bytes if percentage.zero? # I added this as well!
  dpi = (300.0 * percentage / 100).round

  run_ghostscript(input.path, output.path, dpi)
end

def self.progressively_compress(pdf_bytes, attempts: 3, compression_percentage: 10)
  percentage = 100

  attempts.times do
    yield(pdf_bytes)
    percentage -= compression_percentage
    pdf_bytes = compress(pdf_bytes, percentage)
  end
end
```

This looks like a fantastic implementation. With "just" seven iterations the code looks like I wanted it.

Claude was very bad at naming things and doing a proper separation of concerns and good architecture, but at least it
gave me the right ghostscript commands to reduce the PDF size, which would have taken me ages to find out.

Also, I let it write tests in the meantime, and they were all green.

Except that, at a closer look, nothing worked.

At this point the tests revealed a fundamental problem: **Ghostscript's single-pass DPI downsampling doesn't reliably
compress by a given percentage.** For already-compressed PDFs, a single Ghostscript pass at 90% DPI actually *inflated*
the output by 40%+. The `pdfwrite` device decompresses and re-encodes everything.

```
Original: 899'685
90% (270 DPI): 1'258'729  (+40% LARGER!)
80% (240 DPI): 1'072'671  (+19% LARGER!)
70% (210 DPI): 893'270   (finally smaller)
60% (180 DPI): 722'807
50% (150 DPI): 555'228
```

What I found annoying is that I had to explicitly look into the tests to spot this.
They were all green, because it just verified that it worked, but not that the actual generated file size was 10% lower
of the previous one.
Also, it used a fake generated PDF which behaves completely different from a real one: the fake one had just some text,
while a real-world one contained a large image: this changed completely the output.

And this was my entire business logic here!

At this point I let Claude run for ~10 minutes. 10 minutes to figure out the problem.

Until I decided to finally take
over and tell Claude how to do it.

---

## Version 9 (Final): Multi-pass Ghostscript until target is reached

**My feedback:** *"The approach using ghostscript is ok, but the PdfCompressor should take care of invoking ghostscript
multiple times until the desired compression is reached."*

The key insight: a single Ghostscript pass may inflate, but iterating at progressively lower DPI will eventually reach
the target. The `compress` method now loops internally, stepping down DPI by 10 each iteration, until the output is
small enough.

```ruby
# `app/models/ibm_document.rb` — Final version (create method)

MAX_COMPRESSION_ATTEMPTS = 3

def self.create(pdf_file_bytes)
  response = nil

  PdfCompressor.progressively_compress(pdf_file_bytes, attempts: MAX_COMPRESSION_ATTEMPTS) do |bytes|
    response = submit(bytes)
    break if response.success? || !exceeded_message_size?(response)
  end
  response
end
```

```ruby
# `app/services/pdf_compressor.rb` — Final version

class PdfCompressor
  def self.compress(pdf_bytes, percentage)
    return pdf_bytes if percentage.zero?

    tolerance = 1
    target_size = (pdf_bytes.bytesize * (100 - percentage + tolerance) / 100.0).round
    current_bytes = pdf_bytes
    dpi = BASE_DPI

    loop do
      dpi -= DPI_STEP
      break current_bytes if dpi < MIN_DPI

      current_bytes = run_ghostscript_on(current_bytes, dpi)
      break current_bytes if current_bytes.bytesize <= target_size
    end
  end

  def self.progressively_compress(pdf_bytes, attempts: 3, compression_percentage: 10)
    percentage = 0

    attempts.times do
      yield(pdf_bytes)
      percentage += compression_percentage
      pdf_bytes = compress(pdf_bytes, percentage)
    end
  end
end
```

---

## Key takeaways

1. **Separation of concerns needs taste** — the AI initially put everything in one class, then fully separated when
   asked, but extracted the wrong logic into the wrong place. It took several rounds to find the right middle ground:
   `PdfCompressor` owns the loop and compression, the caller owns the break condition. The AI never pushed back or
   proposed alternatives — it just did what was asked.

2. **Naming matters more than you think** — "step" vs "compression_percentage", "retries" vs "attempts", keyword vs
   positional arguments. These seem like nitpicks, but imprecise naming led to wrong semantics: saying "retries" made
   Claude implement `(max_retries + 1).times` instead of the simpler `attempts.times`.

3. **AI-written tests can be dangerously green** — the tests passed, but they used a fake PDF with just text and only
   checked that the output was valid — not that it was actually smaller. With a real scanned document, Ghostscript
   *inflated* the file by 40%. The AI never tested the actual business requirement.

4. **Domain knowledge is irreplaceable** — the AI didn't know that Ghostscript's `pdfwrite` decompresses and
   re-encodes everything, causing inflation at high quality levels. It spent 10 minutes trying alternatives before I
   told it the simple fix: loop at progressively lower DPI until the target is reached.

5. **AI is great at what you'd rather not learn** — despite all the iteration on architecture and naming, the
   Ghostscript command-line flags were correct from the start. That's the part that would have taken me the longest to
   figure out on my own.
