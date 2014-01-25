function [vector] = matchTimes(timeVect,timeIndices,otherTimeVect)

attsegments = zeros(size(timeIndices));
vector = [];
for i = 1:size(timeIndices,1)
    [~,attsegments(i,1)] = min(abs( otherTimeVect - timeVect(timeIndices(i,1)) ));
    [~,attsegments(i,2)] = min(abs( otherTimeVect - timeVect(timeIndices(i,2)) ));
    vector = [vector attsegments(i,1):attsegments(i,2)];
end

end