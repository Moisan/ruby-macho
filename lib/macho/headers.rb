module MachO
  # big-endian fat magic
  FAT_MAGIC = 0xcafebabe

  # little-endian fat magic
  # this is defined, but should never appear in ruby-macho code because
  # fat headers are always big-endian and therefore always unpacked as such.
  FAT_CIGAM = 0xbebafeca

  # 32-bit big-endian magic
  MH_MAGIC = 0xfeedface

  # 32-bit little-endian magic
  MH_CIGAM = 0xcefaedfe

  # 64-bit big-endian magic
  MH_MAGIC_64 = 0xfeedfacf

  # 64-bit little-endian magic
  MH_CIGAM_64 = 0xcffaedfe

  # association of magic numbers to string representations
  MH_MAGICS = {
    FAT_MAGIC => "FAT_MAGIC",
    MH_MAGIC => "MH_MAGIC",
    MH_CIGAM => "MH_CIGAM",
    MH_MAGIC_64 => "MH_MAGIC_64",
    MH_CIGAM_64 => "MH_CIGAM_64"
  }

  # mask for CPUs with 64-bit architectures (when running a 64-bit ABI?)
  CPU_ARCH_ABI64 = 0x01000000

  # any CPU (unused?)
  CPU_TYPE_ANY = -1

  # i386 and later compatible CPUs
  CPU_TYPE_I386 = 0x07

  # x86_64 (AMD64) compatible CPUs
  CPU_TYPE_X86_64 = (CPU_TYPE_I386 | CPU_ARCH_ABI64)

  # 32-bit ARM compatible CPUs
  CPU_TYPE_ARM = 0x0c

  # 64-bit ARM compatible CPUs
  CPU_TYPE_ARM64 = (CPU_TYPE_ARM | CPU_ARCH_ABI64)

  # PowerPC compatible CPUs
  CPU_TYPE_POWERPC = 0x12

  # PowerPC64 compatible CPUs
  CPU_TYPE_POWERPC64 = (CPU_TYPE_POWERPC | CPU_ARCH_ABI64)

  # association of cpu types to symbol representations
  CPU_TYPES = {
    CPU_TYPE_ANY => :any,
    CPU_TYPE_I386 => :i386,
    CPU_TYPE_X86_64 => :x86_64,
    CPU_TYPE_ARM => :arm,
    CPU_TYPE_ARM64 => :arm64,
    CPU_TYPE_POWERPC => :ppc,
    CPU_TYPE_POWERPC64 => :ppc64,
  }

  # mask for CPU subtype capabilities
  CPU_SUBTYPE_MASK = 0xff000000

  # 64-bit libraries (undocumented!)
  # @see http://llvm.org/docs/doxygen/html/Support_2MachO_8h_source.html
  CPU_SUBTYPE_LIB64 = 0x80000000

  # the lowest common sub-type for `CPU_TYPE_I386`
  CPU_SUBTYPE_X86_ALL = 3

  # the lowest common sub-type for `CPU_TYPE_X86_64`
  CPU_SUBTYPE_X86_64_ALL = CPU_SUBTYPE_X86_ALL

  # the Haskell sub-type for `CPU_TYPE_X86_64`
  CPU_SUBTYPE_X86_64_H = 8

  # the lowest common sub-type for `CPU_TYPE_ARM`
  CPU_SUBTYPE_ARM_ALL = 0

  # the v7 sub-type for `CPU_TYPE_ARM`
  CPU_SUBTYPE_ARM_V7 = 9

  # the v7s sub-type for `CPU_TYPE_ARM`
  CPU_SUBTYPE_ARM_V7S = 11

  # the v7k sub-type for `CPU_TYPE_ARM`
  CPU_SUBTYPE_ARM_V7K = 12

  # the v8 sub-type for `CPU_TYPE_ARM`
  CPU_SUBTYPE_ARM_V8 = 13

  # the lowest common sub-type for `CPU_TYPE_ARM64`
  CPU_SUBTYPE_ARM64_ALL = 0

  # the v8 sub-type for `CPU_TYPE_ARM64`
  CPU_SUBTYPE_ARM64_V8 = 1

  # the lowest common sub-type for `CPU_TYPE_POWERPC`
  CPU_SUBTYPE_POWERPC_ALL = 0

  # the 750 (G3) sub-type for `CPU_TYPE_POWERPC`
  CPU_SUBTYPE_POWERPC_750 = 9

  # the 7400 (G4) sub-type for `CPU_TYPE_POWERPC`
  CPU_SUBTYPE_POWERPC_7400 = 10

  # the 7450 (G4 "Voyager") sub-type for `CPU_TYPE_POWERPC`
  CPU_SUBTYPE_POWERPC_7450 = 11

  # the 970 (G5) sub-type for `CPU_TYPE_POWERPC`
  CPU_SUBTYPE_POWERPC_970 = 100

  # any CPU sub-type for CPU type `CPU_TYPE_POWERPC64`
  CPU_SUBTYPE_POWERPC64_ALL = CPU_SUBTYPE_POWERPC_ALL

  # association of CPU types/subtype pairs to symbol representations
  CPU_SUBTYPES = {
    CPU_TYPE_I386 => {
      CPU_SUBTYPE_X86_ALL => :i386,
    }.freeze,
    CPU_TYPE_X86_64 => {
      CPU_SUBTYPE_X86_64_ALL => :x86_64,
      CPU_SUBTYPE_X86_64_H => :x86_64h,
    }.freeze,
    CPU_TYPE_ARM => {
      CPU_SUBTYPE_ARM_ALL => :arm,
      CPU_SUBTYPE_ARM_V7 => :armv7,
      CPU_SUBTYPE_ARM_V7S => :armv7s,
      CPU_SUBTYPE_ARM_V7K => :armv7k,
      CPU_SUBTYPE_ARM_V8 => :armv8,
    }.freeze,
    CPU_TYPE_ARM64 => {
      CPU_SUBTYPE_ARM64_ALL => :arm64,
      CPU_SUBTYPE_ARM64_V8 => :armv8,
    }.freeze,
    CPU_TYPE_POWERPC => {
      CPU_SUBTYPE_POWERPC_ALL => :ppc,
      CPU_SUBTYPE_POWERPC_750 => :ppc750,
      CPU_SUBTYPE_POWERPC_7400 => :ppc7400,
      CPU_SUBTYPE_POWERPC_7450 => :ppc7450,
      CPU_SUBTYPE_POWERPC_970 => :ppc970,
    }.freeze,
    CPU_TYPE_POWERPC64 => {
      CPU_SUBTYPE_POWERPC64_ALL => :ppc64,
    }.freeze,
  }.freeze

  # relocatable object file
  MH_OBJECT = 0x1

  # demand paged executable file
  MH_EXECUTE = 0x2

  # fixed VM shared library file
  MH_FVMLIB = 0x3

  # core dump file
  MH_CORE = 0x4

  # preloaded executable file
  MH_PRELOAD = 0x5

  # dynamically bound shared library
  MH_DYLIB = 0x6

  # dynamic link editor
  MH_DYLINKER = 0x7

  # dynamically bound bundle file
  MH_BUNDLE = 0x8

  # shared library stub for static linking only, no section contents
  MH_DYLIB_STUB = 0x9

  # companion file with only debug sections
  MH_DSYM = 0xa

  # x86_64 kexts
  MH_KEXT_BUNDLE = 0xb

  # association of filetypes to string representations
  # @api private
  MH_FILETYPES = {
    MH_OBJECT => "MH_OBJECT",
    MH_EXECUTE => "MH_EXECUTE",
    MH_FVMLIB => "MH_FVMLIB",
    MH_CORE => "MH_CORE",
    MH_PRELOAD => "MH_PRELOAD",
    MH_DYLIB => "MH_DYLIB",
    MH_DYLINKER => "MH_DYLINKER",
    MH_BUNDLE => "MH_BUNDLE",
    MH_DYLIB_STUB => "MH_DYLIB_STUB",
    MH_DSYM => "MH_DSYM",
    MH_KEXT_BUNDLE => "MH_KEXT_BUNDLE"
  }

  # association of mach header flag symbols to values
  # @api private
  MH_FLAGS = {
    :MH_NOUNDEFS => 0x1,
    :MH_INCRLINK => 0x2,
    :MH_DYLDLINK => 0x4,
    :MH_BINDATLOAD => 0x8,
    :MH_PREBOUND => 0x10,
    :MH_SPLIT_SEGS => 0x20,
    :MH_LAZY_INIT => 0x40,
    :MH_TWOLEVEL => 0x80,
    :MH_FORCE_FLAT => 0x100,
    :MH_NOMULTIDEFS => 0x200,
    :MH_NOPREFIXBINDING => 0x400,
    :MH_PREBINDABLE => 0x800,
    :MH_ALLMODSBOUND => 0x1000,
    :MH_SUBSECTIONS_VIA_SYMBOLS => 0x2000,
    :MH_CANONICAL => 0x4000,
    :MH_WEAK_DEFINES => 0x8000,
    :MH_BINDS_TO_WEAK => 0x10000,
    :MH_ALLOW_STACK_EXECUTION => 0x20000,
    :MH_ROOT_SAFE => 0x40000,
    :MH_SETUID_SAFE => 0x80000,
    :MH_NO_REEXPORTED_DYLIBS => 0x100000,
    :MH_PIE => 0x200000,
    :MH_DEAD_STRIPPABLE_DYLIB => 0x400000,
    :MH_HAS_TLV_DESCRIPTORS => 0x800000,
    :MH_NO_HEAP_EXECUTION => 0x1000000,
    :MH_APP_EXTENSION_SAFE => 0x02000000
  }

  # Fat binary header structure
  # @see MachO::FatArch
  class FatHeader < MachOStructure
    # @return [Fixnum] the magic number of the header (and file)
    attr_reader :magic

    # @return [Fixnum] the number of fat architecture structures following the header
    attr_reader :nfat_arch

    # always big-endian
    FORMAT = "N2"
    SIZEOF = 8

    # @api private
    def initialize(magic, nfat_arch)
      @magic = magic
      @nfat_arch = nfat_arch
    end
  end

  # Fat binary header architecture structure. A Fat binary has one or more of
  # these, representing one or more internal Mach-O blobs.
  # @see MachO::FatHeader
  class FatArch < MachOStructure
    # @return [Fixnum] the CPU type of the Mach-O
    attr_reader :cputype

    # @return [Fixnum] the CPU subtype of the Mach-O
    attr_reader :cpusubtype

    # @return [Fixnum] the file offset to the beginning of the Mach-O data
    attr_reader :offset

    # @return [Fixnum] the size, in bytes, of the Mach-O data
    attr_reader :size

    # @return [Fixnum] the alignment, as a power of 2
    attr_reader :align

    # always big-endian
    FORMAT = "N5"
    SIZEOF = 20

    # @api private
    def initialize(cputype, cpusubtype, offset, size, align)
      @cputype = cputype
      @cpusubtype = cpusubtype
      @offset = offset
      @size = size
      @align = align
    end
  end

  # 32-bit Mach-O file header structure
  class MachHeader < MachOStructure
    # @return [Fixnum] the magic number
    attr_reader :magic

    # @return [Fixnum] the CPU type of the Mach-O
    attr_reader :cputype

    # @return [Fixnum] the CPU subtype of the Mach-O
    attr_reader :cpusubtype

    # @return [Fixnum] the file type of the Mach-O
    attr_reader :filetype

    # @return [Fixnum] the number of load commands in the Mach-O
    attr_reader :ncmds

    # @return [Fixnum] the size of all load commands, in bytes, in the Mach-O
    attr_reader :sizeofcmds

    # @return [Fixnum] the header flags associated with the Mach-O
    attr_reader :flags

    FORMAT = "L=7"
    SIZEOF = 28

    # @api private
    def initialize(magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds,
        flags)
      @magic = magic
      @cputype = cputype
      # For now we're not interested in additional capability bits also to be
      # found in the `cpusubtype` field. We only care about the CPU sub-type.
      @cpusubtype = cpusubtype & ~CPU_SUBTYPE_MASK
      @filetype = filetype
      @ncmds = ncmds
      @sizeofcmds = sizeofcmds
      @flags = flags
    end

    # @example
    #  puts "this mach-o has position-independent execution" if header.flag?(:MH_PIE)
    # @param flag [Symbol] a mach header flag symbol
    # @return [Boolean] true if `flag` is present in the header's flag section
    def flag?(flag)
      flag = MH_FLAGS[flag]
      return false if flag.nil?
      flags & flag == flag
    end
  end

  # 64-bit Mach-O file header structure
  class MachHeader64 < MachHeader
    # @return [void]
    attr_reader :reserved

    FORMAT = "L=8"
    SIZEOF = 32

    # @api private
    def initialize(magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds,
        flags, reserved)
      super(magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags)
      @reserved = reserved
    end
  end
end
