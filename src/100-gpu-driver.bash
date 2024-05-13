get_gpu_driver() {
    case $os in
        "Linux")
            gpu_driver="$(lspci -nnk | awk -F ': ' \
                          '/Display|3D|VGA/{nr[NR+2]}; NR in nr {printf $2 ", "; exit}')"
            gpu_driver="${gpu_driver%, }"

            if [[ "$gpu_driver" == *"nvidia"* ]]; then
                gpu_driver="$(< /proc/driver/nvidia/version)"
                gpu_driver="${gpu_driver/*Module  }"
                gpu_driver="NVIDIA ${gpu_driver/  *}"
            fi
        ;;

        "Mac OS X"|"macOS")
            if [[ "$(kextstat | grep "GeForceWeb")" != "" ]]; then
                gpu_driver="NVIDIA Web Driver"
            else
                gpu_driver="macOS Default Graphics Driver"
            fi
        ;;
    esac
}

