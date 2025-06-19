class simpleFixedPointSignedLongDivision_sequence extends uvm_sequence #(simpleFixedPointSignedLongDivision_transaction);
    `uvm_object_utils(simpleFixedPointSignedLongDivision_sequence)
    
    function new(string name = "simpleFixedPointSignedLongDivision_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        simpleFixedPointSignedLongDivision_transaction trans;
        
        // Apply reset
        trans = simpleFixedPointSignedLongDivision_transaction::type_id::create("trans");
        trans.reset_n = 0;
        start_item(trans);
        finish_item(trans);
        
        // Release reset and send random data
        repeat(10) begin
            trans = simpleFixedPointSignedLongDivision_transaction::type_id::create("trans");
            trans.reset_n = 1;
            assert(trans.randomize());
            start_item(trans);
            finish_item(trans);
        end
    endtask
endclass