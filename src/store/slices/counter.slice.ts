import { createSlice, PayloadAction } from "@reduxjs/toolkit";
type State = { value: number }; const initialState: State = { value: 0 };
const slice = createSlice({
  name: "counter", initialState,
  reducers: { increment: s => { s.value += 1; }, add: (s,a:PayloadAction<number>)=>{s.value+=a.payload;}, reset:()=>initialState }
});
export const { increment, add, reset } = slice.actions; export default slice.reducer;
