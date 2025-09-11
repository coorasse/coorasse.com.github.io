* Stream log lines live. Starting a thread and streaming the lines to the client. Also refresh the screen
* Ensure that lines are sorted correctly
* How to display the line number? Current implementation `head -c "#{last_position}" #{path} | wc -l`.strip.to_i
* Add placeholders for missing log lines. 
* Test speed difference if we did not need line numbers
* Enable/disable autoscroll
* Live / Search mode
* grep and supergrep to search large files (1GB)
* issues with ANSI characters when searching
* keep colors if present, grep and stream
* reduce memory usage when grepping over big files
* stream log lines
* improve javascript performance to reduce the work necessary: batch elaboration of new log lines
* possible issue: network delay. solution: batch lines in fewer websocket calls
    
