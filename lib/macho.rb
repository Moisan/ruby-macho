require "./lib/cstruct.rb"
require "./lib/macho/file"
require "./lib/macho/exceptions"

# http://www.opensource.apple.com/source/cctools/cctools-870/include/mach-o/loader.h
# http://www.opensource.apple.com/source/cctools/cctools-870/include/mach-o/fat.h

module MachO
	# 'Fat' binaries envelop Mach-O binaries so include them for completeness,
	# Fat binary header structure
	class FatHeader < CStruct
		uint32 :magic
		uint32 :nfat_arch # number of FatArchs that follow
	end

	# Fat binary architecture structure
	class FatArch < CStruct
		int32 :cputype
		int32 :cpusubtype
		uint32 :offset
		uint32 :size
		uint32 :align
	end

	FAT_MAGIC = 0xcafebabe # big-endian fat magic
	FAT_CIGAM = 0xbebafeca # little-endian fat magic

	# 32-bit Mach-O file header structure
	class MachHeader < CStruct
		uint32 :magic
		int32 :cputype
		int32 :cpusubtype
		uint32 :filetype
		uint32 :ncmds
		uint32 :sizeofcmds
		uint32 :flags
	end

	MH_MAGIC = 0xfeedface # 32-bit big-endian magic
	MH_CIGAM = 0xcefaedfe # 32-bit little-endian magic

	# 64-bit Mach-O file header structure
	class MachHeader64 < CStruct
		uint32 :magic
		int32 :cputype
		int32 :cpusubtype
		uint32 :filetype
		uint32 :ncmds
		uint32 :sizeofcmds
		uint32 :flags
		uint32 :reserved
	end

	MH_MAGIC_64 = 0xfeedfacf # 64-bit big-endian magic
	MH_CIGAM_64 = 0xcffaedfe # 64-bit little-endian magic

	MH_MAGICS = {
		FAT_MAGIC => "FAT_MAGIC",
		FAT_CIGAM => "FAT_CIGAM",
		MH_MAGIC => "MH_MAGIC",
		MH_CIGAM => "MH_CIGAM",
		MH_MAGIC_64 => "MH_MAGIC_64",
		MH_CIGAM_64 => "MH_CIGAM_64"
	}

	# capability bits used in the definition of cputype
	CPU_ARCH_MASK = 0xff000000
	CPU_ARCH_ABI64 = 0x01000000

	# (select) values for cputype in MachHeader/MachHeader64
	CPU_TYPE_ANY = -1
	CPU_TYPE_X86 = 0x07
	CPU_TYPE_I386 = CPU_TYPE_X86
	CPU_TYPE_X86_64 = (CPU_TYPE_X86 | CPU_ARCH_ABI64)
	CPU_TYPE_POWERPC = 0x24 # 18
	CPU_TYPE_POWERPC64 = (CPU_TYPE_POWERPC | CPU_ARCH_ABI64)

	# convenience array of CPU types
	CPU_TYPES = {
		CPU_TYPE_ANY => "CPU_TYPE_ANY",
		CPU_TYPE_X86 => "CPU_TYPE_X86",
		CPU_TYPE_I386 => "CPU_TYPE_I386",
		CPU_TYPE_X86_64 => "CPU_TYPE_X86_64",
		CPU_TYPE_POWERPC => "CPU_TYPE_POWERPC",
		CPU_TYPE_POWERPC64 => "CPU_TYPE_POWERPC64"
	}

	# capability bits used in the definition of cpusubtype
	# http://llvm.org/docs/doxygen/html/Support_2MachO_8h_source.html
	CPU_SUBTYPE_MASK = 0xff000000
	CPU_SUBTYPE_LIB64 = 0x80000000

	# (select) cpusubtypes
	CPU_SUBTYPE_X86_ALL = 3
	CPU_SUBTYPE_X86_ARCH1 = 4

	CPU_SUBTYPES = {
		CPU_SUBTYPE_X86_ALL => "CPU_SUBTYPE_X86_ALL",
		CPU_SUBTYPE_X86_ARCH1 => "CPU_SUBTYPE_X86_ARCH1"
	}

	# values for filetype in MachHeader/MachHeader64
	MH_OBJECT = 0x1			# relocatable object file
	MH_EXECUTE = 0x2		# demand paged executable file
	MH_FVMLIB = 0x3			# fixed VM shared library file
	MH_CORE = 0x4			# core file
	MH_PRELOAD = 0x5		# preloaded executable file
	MH_DYLIB = 0x6			# dynamically bound shared library
	MH_DYLINKER = 0x7		# dynamic link editor
	MH_BUNDLE = 0x8			# dynamically bound bundle file
	MH_DYLIB_STUB = 0x9		# shared library stub for static linking only no,
							# section contents
	MH_DSYM = 0xa			# companion file with only debug sections
	MH_KEXT_BUNDLE = 0xb	# x86_64 lexts

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

	# TODO: declare values for flags in MachHeader/MachHeader64

	# general purpose pseudo-structure
	class MachOStructure
		@format = nil
		@sizeof = 0

		def self.bytesize
			@sizeof
		end

		def self.new_from_bin(bin)
			self.new(*bin.unpack(@format))
		end
	end

	# Mach-O load command structure
	class LoadCommand < MachOStructure
		attr_reader :offset, :cmd, :cmdsize

		@format = "VV"
		@sizeof = 8

		def self.new_from_bin(offset, bin)
			self.new(offset, *bin.unpack(@format))
		end

		def initialize(offset, cmd, cmdsize)
			@offset = offset
			@cmd = cmd
			@cmdsize = cmdsize
		end

		def to_s
			LOAD_COMMANDS[cmd]
		end
	end

	# After MacOS X 10.1 when a new load command is added that is required to be
	# understood by the dynamic linker for the image to execute properly the
	# LC_REQ_DYLD bit will be or'ed into the load command constant.  If the dynamic
	# linker sees such a load command it it does not understand will issue a
	# "unknown load command required for execution" error and refuse to use the
	# image.  Other load commands without this bit that are not understood will
	# simply be ignored.
	LC_REQ_DYLD = 0x80000000

	# values for cmd in LoadCommand
	LC_SEGMENT = 0x1
	LC_SYMTAB = 0x2
	LC_SYMSEC = 0x3
	LC_THREAD = 0x4
	LC_UNIXTHREAD = 0x5
	LC_LOADFVMLIB = 0x6
	LC_IDFVMLIB = 0x7
	LC_IDENT = 0x8
	LC_FVMFILE = 0x9
	LC_PREPAGE = 0xa
	LC_DYSYMTAB = 0xb
	LC_LOAD_DYLIB = 0xc
	LC_ID_DYLIB = 0xd
	LC_LOAD_DYLINKER = 0xe
	LC_ID_DYLINKER = 0xf
	LC_PREBOUND_DYLIB = 0x10
	LC_ROUTINES = 0x11
	LC_SUB_FRAMEWORK = 0x12
	LC_SUB_UMBRELLA = 0x13
	LC_SUB_CLIENT = 0x14
	LC_SUB_LIBRARY = 0x15
	LC_TWOLEVEL_HINTS = 0x16
	LC_PREBIND_CKSUM = 0x17
	LC_LOAD_WEAK_DYLIB = (0x18 | LC_REQ_DYLD)
	LC_SEGMENT_64 = 0x19
	LC_ROUTINES_64 = 0x1a
	LC_UUID = 0x1b
	LC_RPATH = (0x1c | LC_REQ_DYLD)
	LC_CODE_SIGNATURE = 0x1d
	LC_SEGMENT_SPLIT_INFO = 0x1e
	LC_REEXPORT_DYLIB = (0x1f | LC_REQ_DYLD)
	LC_LAZY_LOAD_DYLIB = 0x20
	LC_ENCRYPTION_INFO = 0x21
	LC_DYLD_INFO = 0x22
	LC_DYLD_INFO_ONLY = (0x22 | LC_REQ_DYLD)
	LC_LOAD_UPWARD_DYLIB = (0x23 | LC_REQ_DYLD)
	LC_VERSION_MIN_MACOSX = 0x24
	LC_VERSION_MIN_IPHONEOS = 0x25
	LC_FUNCTION_STARTS = 0x26
	LC_DYLD_ENVIRONMENT = 0x27
	LC_MAIN = (0x28 | LC_REQ_DYLD)
	LC_DATA_IN_CODE = 0x29
	LC_SOURCE_VERSION = 0x2a
	LC_DYLIB_CODE_SIGN_DRS = 0x2b
	LC_ENCRYPTION_INFO_64 = 0x2c
	LC_LINKER_OPTION = 0x2d
	LC_LINKER_OPTIMIZATION_HINT = 0x2e

	LOAD_COMMANDS = {
		LC_SEGMENT => "LC_SEGMENT",
		LC_SYMTAB => "LC_SYMTAB",
		LC_SYMSEC => "LC_SYMSEC",
		LC_THREAD => "LC_THREAD",
		LC_UNIXTHREAD => "LC_UNIXTHREAD",
		LC_LOADFVMLIB => "LC_LOADFVMLIB",
		LC_IDFVMLIB => "LC_IDFVMLIB",
		LC_IDENT => "LC_IDENT",
		LC_FVMFILE => "LC_FVMFILE",
		LC_PREPAGE => "LC_PREPAGE",
		LC_DYSYMTAB => "LC_DYSYMTAB",
		LC_LOAD_DYLIB => "LC_LOAD_DYLIB",
		LC_ID_DYLIB => "LC_ID_DYLIB",
		LC_LOAD_DYLINKER => "LC_LOAD_DYLINKER",
		LC_ID_DYLINKER => "LC_ID_DYLINKER",
		LC_PREBOUND_DYLIB => "LC_PREBOUND_DYLIB",
		LC_ROUTINES => "LC_ROUTINES",
		LC_SUB_FRAMEWORK => "LC_SUB_FRAMEWORK",
		LC_SUB_UMBRELLA => "LC_SUB_UMBRELLA",
		LC_SUB_CLIENT => "LC_SUB_CLIENT",
		LC_SUB_LIBRARY => "LC_SUB_LIBRARY",
		LC_TWOLEVEL_HINTS => "LC_TWOLEVEL_HINTS",
		LC_PREBIND_CKSUM => "LC_PREBIND_CKSUM",
		LC_LOAD_WEAK_DYLIB => "LC_LOAD_WEAK_DYLIB",
		LC_SEGMENT_64 => "LC_SEGMENT_64",
		LC_ROUTINES_64 => "LC_ROUTINES_64",
		LC_UUID => "LC_UUID",
		LC_RPATH => "LC_RPATH",
		LC_CODE_SIGNATURE => "LC_CODE_SIGNATURE",
		LC_SEGMENT_SPLIT_INFO => "LC_SEGMENT_SPLIT_INFO",
		LC_REEXPORT_DYLIB => "LC_REEXPORT_DYLIB",
		LC_LAZY_LOAD_DYLIB => "LC_LAZY_LOAD_DYLIB",
		LC_ENCRYPTION_INFO => "LC_ENCRYPTION_INFO",
		LC_DYLD_INFO => "LC_DYLD_INFO",
		LC_DYLD_INFO_ONLY => "LC_DYLD_INFO_ONLY",
		LC_LOAD_UPWARD_DYLIB => "LC_LOAD_UPWARD_DYLIB",
		LC_VERSION_MIN_MACOSX => "LC_VERSION_MIN_MACOSX",
		LC_VERSION_MIN_IPHONEOS => "LC_VERSION_MIN_IPHONEOS",
		LC_FUNCTION_STARTS => "LC_FUNCTION_STARTS",
		LC_DYLD_ENVIRONMENT => "LC_DYLD_ENVIRONMENT",
		LC_MAIN => "LC_MAIN",
		LC_DATA_IN_CODE => "LC_DATA_IN_CODE",
		LC_SOURCE_VERSION => "LC_SOURCE_VERSION",
		LC_DYLIB_CODE_SIGN_DRS => "LC_DYLIB_CODE_SIGN_DRS",
		LC_ENCRYPTION_INFO_64 => "LC_ENCRYPTION_INFO_64",
		LC_LINKER_OPTION => "LC_LINKER_OPTION",
		LC_LINKER_OPTIMIZATION_HINT => "LC_LINKER_OPTIMIZATION_HINT"
	}

	class UUIDCommand < LoadCommand
		attr_reader :uuid

		@format = "VVa16"
		@sizeof = 24

		def initialize(offset, cmd, cmdsize, uuid)
			super(offset, cmd, cmdsize)
			@uuid = uuid.unpack("C16") # re-unpack for the actual UUID array
		end
	end

	class SegmentCommand < LoadCommand
		attr_reader :segname, :vmaddr, :vmsize, :fileoff, :filesize, :maxprot
		attr_reader :initprot, :nsects, :flags

		@format = "VVa16VVVVVVVV"
		@sizeof = 56

		def initialize(offset, cmd, cmdsize, segname, vmaddr, vmsize, fileoff,
				filesize, maxprot, initprot, nsects, flags)
			super(offset, cmd, cmdsize)
			@segname = segname
			@vmaddr = vmaddr
			@vmsize = vmsize
			@fileoff = fileoff
			@filesize = filesize
			@maxprot = maxprot
			@initprot = initprot
			@nsects = nsects
			@flags = flags
		end

		def segment_name
			@segname.delete("\x00")
		end
	end

	class SegmentCommand64 < LoadCommand
		attr_reader :segname, :vmaddr, :vmsize, :fileoff, :filesize, :maxprot
		attr_reader :initprot, :nsects, :flags

		@format = "VVa16QQQQVVVV"
		@sizeof = 72

		def initialize(offset, cmd, cmdsize, segname, vmaddr, vmsize, fileoff,
				filesize, maxprot, initprot, nsects, flags)
			super(offset, cmd, cmdsize)
			@segname = segname
			@vmaddr = vmaddr
			@vmsize = vmsize
			@fileoff = fileoff
			@filesize = filesize
			@maxprot = maxprot
			@initprot = initprot
			@nsects = nsects
			@flags = flags
		end

		def segment_name
			@segname.delete("\x00")
		end
	end

	# the lc_str and dylib structures have been collapsed
	class DylibCommand < LoadCommand
		attr_reader :name, :timestamp, :current_version, :compatibility_version

		@format = "VVVVVV"
		@sizeof = 24

		def initialize(offset, cmd, cmdsize, name, timestamp, current_version,
				compatibility_version)
			super(offset, cmd, cmdsize)
			@name = name
			@timestamp = timestamp
			@current_version = current_version
			@compatibility_version = compatibility_version
		end
	end

	class DylinkerCommand < LoadCommand
		attr_reader :name

		@format = "VVV"
		@sizeof = 12

		def initialize(offset, cmd, cmdsize, name)
			super(offset, cmd, cmdsize)
			@name = name
		end
	end

	class PreboundDylibCommand < LoadCommand
		attr_reader :name, :nmodules, :linked_modules

		@format = "VVVVV"
		@sizeof = 20

		def initialize(offset, cmd, cmdsize, name, nmodules, linked_modules)
			super(offset, cmd, cmdsize)
			@name = name
			@nmodules = nmodules
			@linked_modules = linked_modules
		end
	end

	# NOTE: cctools-870 has all fields of thread_command commented out
	# except common ones (cmd, cmdsize)
	class ThreadCommand < LoadCommand

	end

	class RoutinesCommand < LoadCommand
		attr_reader :init_address, :init_module, :reserved1, :reserved2
		attr_reader :reserved3, :reserved4, :reserved5, :reserved6

		@format = "VVVVVVVVVV"
		@sizeof = 40

		def initialize(offset, cmd, cmdsize, init_address, init_module,
				reserved1, reserved2, reserved3, reserved4, reserved5,
				reserved6)
			super(offset, cmd, cmdsize)
			@init_address = init_address
			@init_module = init_module
			@reserved1 = reserved1
			@reserved2 = reserved2
			@reserved3 = reserved3
			@reserved4 = reserved4
			@reserved5 = reserved5
			@reserved6 = reserved6
		end
	end

	class RoutinesCommand64 < LoadCommand
		attr_reader :init_address, :init_module, :reserved1, :reserved2
		attr_reader :reserved3, :reserved4, :reserved5, :reserved6

		@format = "VVQQQQQQQQ"
		@sizeof = 72

		def initialize(offset, cmd, cmdsize, init_address, init_module,
				reserved1, reserved2, reserved3, reserved4, reserved5,
				reserved6)
			super(offset, cmd, cmdsize)
			@init_address = init_address
			@init_module = init_module
			@reserved1 = reserved1
			@reserved2 = reserved2
			@reserved3 = reserved3
			@reserved4 = reserved4
			@reserved5 = reserved5
			@reserved6 = reserved6
		end
	end

	class SubFrameworkCommand < LoadCommand
		attr_reader :umbrella

		@format = "VVV"
		@sizeof = 12

		def initialize(offset, cmd, cmdsize, umbrella)
			super(offset, cmd, cmdsize)
			@umbrella = umbrella
		end
	end

	class SubUmbrellaCommand < LoadCommand
		attr_reader :sub_umbrella

		@format = "VVV"
		@sizeof = 12

		def initialize(offset, cmd, cmdsize, sub_umbrella)
			super(offset, cmd, cmdsize)
			@sub_umbrella = sub_umbrella
		end
	end

	class SubLibraryCommand < LoadCommand
		attr_reader :sub_library

		@format = "VVV"
		@sizeof = 12

		def initialize(offset, cmd, cmdsize, sub_library)
			super(offset, cmd, cmdsize)
			@sub_library = sub_library
		end
	end

	class SubClientCommand < LoadCommand
		attr_reader :sub_client

		@format = "VVV"
		@sizeof = 12

		def initialize(offset, cmd, cmdsize, sub_client)
			super(offset, cmd, cmdsize)
			@sub_client = sub_client
		end
	end

	class SymtabCommand < LoadCommand
		attr_reader :symoff, :nsyms, :stroff, :strsize

		@format = "VVVVVV"
		@sizeof = 24

		def initialize(offset, cmd, cmdsize, symoff, nsyms, stroff, strsize)
			super(offset, cmd, cmdsize)
			@symoff = symoff
			@nsyms = nsyms
			@stroff = stroff
			@strsize = strsize
		end
	end

	class DysymtabCommand < LoadCommand
		attr_reader :ilocalsym, :nlocalsym, :iextdefsym, :nextdefsym
		attr_reader :iundefsym, :nundefsym, :tocoff, :ntoc, :modtaboff
		attr_reader :nmodtab, :extrefsymoff, :nextrefsyms, :indirectsymoff
		attr_reader :nindirectsyms, :extreloff, :nextrel, :locreloff, :nlocrel

		@format = "VVVVVVVVVVVVVVVVVVVV"
		@sizeof = 80

		# ugh
		def initialize(offset, cmd, cmdsize, ilocalsym, nlocalsym, iextdefsym,
				nextdefsym, iundefsym, nundefsym, tocoff, ntoc, modtaboff,
				nmodtab, extrefsymoff, nextrefsyms, indirectsymoff,
				nindirectsyms, extreloff, nextrel, locreloff, nlocrel)
			super(offset, cmd, cmdsize)
			@ilocalsym = ilocalsym
			@nlocalsym = nlocalsym
			@iextdefsym = iextdefsym
			@nextdefsym = nextdefsym
			@iundefsym = iundefsym
			@nundefsym = nundefsym
			@tocoff = tocoff
			@ntoc = ntoc
			@modtaboff = modtaboff
			@nmodtab = nmodtab
			@extrefsymoff = extrefsymoff
			@nextrefsyms = nextrefsyms
			@indirectsymoff = indirectsymoff
			@nindirectsyms = nindirectsyms
			@extreloff = extreloff
			@nextrel = nextrel
			@locreloff = locreloff
			@nlocrel = nlocrel
		end
	end

	class Section < MachOStructure
		attr_reader :sectname, :segname, :addr, :size, :offset, :align, :reloff
		attr_reader :nreloc, :flags, :reserved1, :reserved2

		@format = "a16a16VVVVVVVVV"
		@sizeof = 68

		def initialize(sectname, segname, addr, size, offset, align, reloff,
				nreloc, flags, reserved1, reserved2)
			@sectname = sectname
			@segname = segname
			@addr = addr
			@size = size
			@offset = offset
			@align = align
			@reloff = reloff
			@nreloc = nreloc
			@flags = flags
			@reserved1 = reserved1
			@reserved2 = reserved2
		end

		def section_name
			@sectname.delete("\x00")
		end

		def segment_name
			@segname.delete("\x00")
		end
	end

	class Section64 < MachOStructure
		attr_reader :sectname, :segname, :addr, :size, :offset, :align, :reloff
		attr_reader :nreloc, :flags, :reserved1, :reserved2, :reserved3

		@format = "a16a16QQVVVVVVVV"
		@sizeof = 80

		def initialize(sectname, segname, addr, size, offset, align, reloff,
				nreloc, flags, reserved1, reserved2, reserved3)
			@sectname = sectname
			@segname = segname
			@addr = addr
			@size = size
			@offset = offset
			@align = align
			@reloff = reloff
			@nreloc = nreloc
			@flags = flags
			@reserved1 = reserved1
			@reserved2 = reserved2
			@reserved3 = reserved3
		end

		def section_name
			@sectname.delete("\x00")
		end

		def segment_name
			@segname.delete("\x00")
		end
	end

	LC_STRUCTURES = {
		LC_SEGMENT => SegmentCommand,
		LC_SYMTAB => SymtabCommand,
		LC_SYMSEC => LoadCommand,
		LC_THREAD => LoadCommand,
		LC_UNIXTHREAD => LoadCommand,
		LC_LOADFVMLIB => LoadCommand,
		LC_IDFVMLIB => LoadCommand,
		LC_IDENT => LoadCommand,
		LC_FVMFILE => LoadCommand,
		LC_PREPAGE => LoadCommand,
		LC_DYSYMTAB => DysymtabCommand,
		LC_LOAD_DYLIB => DylibCommand,
		LC_ID_DYLIB => DylibCommand,
		LC_LOAD_DYLINKER => DylinkerCommand,
		LC_ID_DYLINKER => DylinkerCommand,
		LC_PREBOUND_DYLIB => PreboundDylibCommand,
		LC_ROUTINES => RoutinesCommand,
		LC_SUB_FRAMEWORK => SubFrameworkCommand,
		LC_SUB_UMBRELLA => SubUmbrellaCommand,
		LC_SUB_CLIENT => SubClientCommand,
		LC_SUB_LIBRARY => SubLibraryCommand,
		LC_TWOLEVEL_HINTS => LoadCommand,
		LC_PREBIND_CKSUM => LoadCommand,
		LC_LOAD_WEAK_DYLIB => LoadCommand,
		LC_SEGMENT_64 => SegmentCommand64,
		LC_ROUTINES_64 => RoutinesCommand64,
		LC_UUID => UUIDCommand,
		LC_RPATH => LoadCommand,
		LC_CODE_SIGNATURE => LoadCommand,
		LC_SEGMENT_SPLIT_INFO => LoadCommand,
		LC_REEXPORT_DYLIB => LoadCommand,
		LC_LAZY_LOAD_DYLIB => LoadCommand,
		LC_ENCRYPTION_INFO => LoadCommand,
		LC_DYLD_INFO => LoadCommand,
		LC_DYLD_INFO_ONLY => LoadCommand,
		LC_LOAD_UPWARD_DYLIB => LoadCommand,
		LC_VERSION_MIN_MACOSX => LoadCommand,
		LC_VERSION_MIN_IPHONEOS => LoadCommand,
		LC_FUNCTION_STARTS => LoadCommand,
		LC_DYLD_ENVIRONMENT => LoadCommand,
		LC_MAIN => LoadCommand,
		LC_DATA_IN_CODE => LoadCommand,
		LC_SOURCE_VERSION => LoadCommand,
		LC_DYLIB_CODE_SIGN_DRS => LoadCommand,
		LC_ENCRYPTION_INFO_64 => LoadCommand,
		LC_LINKER_OPTION => LoadCommand,
		LC_LINKER_OPTIMIZATION_HINT => LoadCommand
	}

	def self.magic?(num)
		num == FAT_MAGIC || num == FAT_CIGAM || num == MH_MAGIC ||
		num == MH_CIGAM || num == MH_MAGIC_64 || num == MH_CIGAM_64
	end

	def self.fat_magic?(num)
		num == FAT_MAGIC || num == FAT_CIGAM
	end

	def self.magic32?(num)
		num == MH_MAGIC || num == MH_CIGAM
	end

	def self.magic64?(num)
		num == MH_MAGIC_64 || num == MH_CIGAM_64
	end
end
