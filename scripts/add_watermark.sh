
if [ ! -z "$WATERMARK" ]; then
	sed -i '' '/public class SorcManager: SorcManagerType {/ a\
    \ \ \ \ private let wm="'$WATERMARK'" \
	' SecureAccessBLE/Classes/Managers/SorcManager/SorcManager.swift

    echo "Watermark added"
else
    echo "No watermark defined"
fi
