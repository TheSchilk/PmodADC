function [audio, fail_count] = adc_read_openport(sport, nsamples)
%ADC_READ_OPENPORT Read nsamples from the ADC connected to serialdevice sport.
%
%   Returns the collection audio samples (uint16), and the number of 
%   packages that failed to decode. 
%   Otherwise functionally identical to adc_read, but can be used to 
%   avoid re-opening the serialdevice every time for 
%   successive measurements.

    % Record Data
    raw_data_count = nsamples*2;
    raw_data = zeros(nsamples, 1,'uint8');
    index = 1;
    flush(sport)
    while index <= raw_data_count
        % Read all available bytes
        samples_read = read(sport, max(sport.NumBytesAvailable,1), "uint8");
            
        % Fill read bytes into samples
        for i = 1:size(samples_read,2)
             raw_data(index) = samples_read(i);
             index = index + 1;
             if index > raw_data_count
                break
             end
        end
    end

    % Decode Samples
    audio = zeros(nsamples, 1,'uint16');
    fail_count = 0;
    sample_count = 0;
    looking_for_pckg = 1;
    sample = 0;

    for i = 1:size(raw_data,1)
        raw = uint16(raw_data(i));
        if looking_for_pckg ==1
            if bitand(raw, uint16(0x80)) ~= 0
                % Is first package, as expected
                sample = bitshift(bitand(raw, uint16(0x7F)),7);
                looking_for_pckg = 2;
            else
                % is not the expected first package
                fail_count = fail_count + 1;
            end
        else 
            if bitand(raw, 0x0080) == 0
                % Is second package, as expected
                sample = bitor(sample, bitand(raw, uint16(0x7F)));
                
                % Sample is done
                sample_count = sample_count + 1;
                audio(sample_count) = sample;
                sample = 0;
                looking_for_pckg = 1;
            else
                % is not the expected second package
                sample = 0;
                looking_for_pckg = 1;
                fail_count = fail_count + 1;
            end
        end
    end
    
    % Cut off extra pre-allocated spaces:
    audio = audio(1:sample_count);
end

