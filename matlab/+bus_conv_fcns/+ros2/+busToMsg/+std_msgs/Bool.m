function rosmsgOut = Bool(slBusIn, rosmsgOut)
%#codegen
%   Copyright 2021 The MathWorks, Inc.
    rosmsgOut.data = logical(slBusIn.data);
end
